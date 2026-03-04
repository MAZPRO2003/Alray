import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';

const formatDate = (date) => {
    if (!date) return '—';
    const d = date.toDate ? date.toDate() : new Date(date);
    return d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
};

// jsPDF doesn't natively support the ₹ symbol without custom loaded fonts, so we use Rs.
const formatCurrencyPDF = (amount) => {
    const formatted = new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 }).format(amount || 0);
    return `Rs. ${formatted}`;
};

// CSV can support the native ₹ symbol, provided the CSV string has a UTF-8 BOM
const formatCurrencyCSV = (amount) => {
    return new Intl.NumberFormat('en-IN', {
        style: 'currency', currency: 'INR', maximumFractionDigits: 0
    }).format(amount || 0);
};

const setupDoc = (title, project) => {
    const doc = new jsPDF();
    doc.setFontSize(22);
    doc.setTextColor(31, 41, 55);
    doc.text('Alray Associates', 14, 20);
    doc.setFontSize(14);
    doc.setTextColor(14, 165, 233); // sky-500
    doc.text(title, 14, 30);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Project: ${project?.name || 'N/A'}`, 14, 40);
    doc.text(`Client: ${project?.clientName || 'N/A'}`, 14, 45);
    doc.text(`Location: ${project?.location || 'N/A'}`, 14, 50);
    doc.text(`Generated: ${formatDate(new Date())}`, 14, 55);
    return doc;
};

// Material & Specialized
export const generateFinancialReportPDF = (project, title, paidItems, pendingItems, mode) => {
    const doc = setupDoc(`${title} Report - ${mode.toUpperCase()}`, project);
    let startY = 65;

    if (mode === 'paid' || mode === 'combined') {
        const totalPaid = paidItems.reduce((sum, i) => sum + (i.amount || 0), 0);
        doc.setFontSize(14);
        doc.setTextColor(31, 41, 55);
        doc.text(`Paid Items (Total: ${formatCurrencyPDF(totalPaid)})`, 14, startY);
        startY += 5;

        if (paidItems.length > 0) {
            const rows = paidItems.map(i => [
                formatDate(i.date),
                i.description,
                i.category || i.type || '-',
                i.quantity ? `${i.quantity} ${i.unit || ''}` : '-',
                formatCurrencyPDF(i.amount)
            ]);
            autoTable(doc, {
                startY,
                head: [['Date', 'Description', 'Category', 'Qty', 'Amount Paid']],
                body: rows,
                theme: 'striped',
                styles: { fontSize: 9 }
            });
            startY = doc.lastAutoTable.finalY + 15;
        } else {
            doc.setFontSize(10);
            doc.text('No paid records found.', 14, startY + 5);
            startY += 15;
        }
    }

    if (mode === 'pending' || mode === 'combined') {
        const totalPending = pendingItems.reduce((sum, i) => sum + (i.remainingAmount || 0), 0);
        doc.setFontSize(14);
        doc.setTextColor(31, 41, 55);
        doc.text(`Pending Bills (Total Owed: ${formatCurrencyPDF(totalPending)})`, 14, startY);
        startY += 5;

        if (pendingItems.length > 0) {
            const rows = pendingItems.map(i => [
                i.vendorName || '-',
                i.description || '-',
                formatDate(i.dueDate),
                formatCurrencyPDF(i.remainingAmount)
            ]);
            autoTable(doc, {
                startY,
                head: [['Vendor', 'Description', 'Due Date', 'Balance Owed']],
                body: rows,
                theme: 'striped',
                styles: { fontSize: 9 }
            });
        } else {
            doc.setFontSize(10);
            doc.text('No pending bills found.', 14, startY + 5);
        }
    }

    doc.save(`${title}_${mode}_${project?.name || 'Project'}.pdf`);
};

export const generateFinancialReportCSV = (project, title, paidItems, pendingItems, mode) => {
    // Add UTF-8 BOM \uFEFF so Excel displays ₹ correctly
    let csv = "data:text/csv;charset=utf-8,\uFEFF";
    csv += `PROJECT,${project?.name || 'N/A'}\nREPORT,${title} - ${mode.toUpperCase()}\n\n`;

    if (mode === 'paid' || mode === 'combined') {
        csv += "PAID ITEMS\nDate,Description,Category,Quantity,Unit,Amount Paid\n";
        paidItems.forEach(i => {
            csv += `"${formatDate(i.date)}","${i.description}","${i.category || i.type || ''}",${i.quantity || ''},"${i.unit || ''}","${formatCurrencyCSV(i.amount)}"\n`;
        });
        csv += "\n";
    }

    if (mode === 'pending' || mode === 'combined') {
        csv += "PENDING BILLS\nVendor,Description,Due Date,Balance Owed\n";
        pendingItems.forEach(i => {
            csv += `"${i.vendorName || ''}","${i.description || ''}","${formatDate(i.dueDate)}","${formatCurrencyCSV(i.remainingAmount)}"\n`;
        });
    }

    const encodedUri = encodeURI(csv);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `${title}_${mode}_${project?.name || 'Project'}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
};

// Customer Tab Export
export const generateCustomerReportPDF = (project, revenues) => {
    const doc = setupDoc('Customer Payments Report', project);
    const totalCollected = revenues.reduce((sum, r) => sum + (r.amount || 0), 0);
    const pendingAmount = Math.max(0, (project?.contractValue || 0) - totalCollected);

    doc.setFontSize(12);
    doc.text(`Total Contract Value: ${formatCurrencyPDF(project?.contractValue || 0)}`, 14, 65);
    doc.text(`Total Collected: ${formatCurrencyPDF(totalCollected)}`, 14, 72);
    doc.text(`Balance Due: ${formatCurrencyPDF(pendingAmount)}`, 14, 79);

    if (revenues.length > 0) {
        const rows = revenues.map(r => [
            formatDate(r.date),
            r.reference || '-',
            r.paymentMethod || '-',
            r.notes || '-',
            formatCurrencyPDF(r.amount)
        ]);
        autoTable(doc, {
            startY: 90,
            head: [['Date', 'Reference', 'Method', 'Notes', 'Amount']],
            body: rows,
            theme: 'striped',
            headStyles: { fillColor: [59, 130, 246] }
        });
    }

    doc.save(`Customer_Payments_${project?.name || 'Project'}.pdf`);
};

export const generateCustomerReportCSV = (project, revenues) => {
    let csv = "data:text/csv;charset=utf-8,\uFEFF";
    csv += `PROJECT,${project?.name || 'N/A'}\nREPORT,Customer Payments\n\n`;
    csv += "Date,Reference,Method,Notes,Amount\n";
    revenues.forEach(r => {
        csv += `"${formatDate(r.date)}","${r.reference || ''}","${r.paymentMethod || ''}","${r.notes || ''}","${formatCurrencyCSV(r.amount)}"\n`;
    });

    const encodedUri = encodeURI(csv);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `Customer_Payments_${project?.name || 'Project'}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
};

// Overall Project Export
export const generateOverallReportPDF = (project, stats) => {
    const doc = setupDoc('Overall Project Summary', project);
    const {
        totalReceived, totalSpent, pendingReceived,
        pendingPayables, remainingBudget, health
    } = stats;

    doc.setFontSize(14);
    doc.setTextColor(31, 41, 55);
    doc.text('Financial Overview', 14, 65);

    autoTable(doc, {
        startY: 70,
        head: [['Metric', 'Amount']],
        body: [
            ['Total Budget', formatCurrencyPDF(project?.budget || 0)],
            ['Total Received', formatCurrencyPDF(totalReceived)],
            ['Total Spent', formatCurrencyPDF(totalSpent)],
            ['Remaining Budget', formatCurrencyPDF(remainingBudget)],
            ['Pending from Customer', formatCurrencyPDF(pendingReceived)],
            ['Pending to Vendors', formatCurrencyPDF(pendingPayables)],
        ],
        theme: 'striped',
        headStyles: { fillColor: [14, 165, 233] },
        styles: { fontSize: 10 }
    });

    let startY = doc.lastAutoTable.finalY + 15;

    doc.setFontSize(14);
    doc.text(`Project Health: ${health.label}`, 14, startY);

    doc.save(`Overall_Summary_${project?.name || 'Project'}.pdf`);
};

export const generateOverallReportCSV = (project, stats) => {
    let csv = "data:text/csv;charset=utf-8,\uFEFF";
    csv += `PROJECT,${project?.name || 'N/A'}\nREPORT,Overall Project Summary\n\n`;
    csv += `Health Status,${stats.health.label}\n\n`;

    csv += "FINANCIAL OVERVIEW\nMetric,Amount\n";
    csv += `Total Budget,"${formatCurrencyCSV(project?.budget || 0)}"\n`;
    csv += `Total Received,"${formatCurrencyCSV(stats.totalReceived || 0)}"\n`;
    csv += `Total Spent,"${formatCurrencyCSV(stats.totalSpent || 0)}"\n`;
    csv += `Remaining Budget,"${formatCurrencyCSV(stats.remainingBudget || 0)}"\n`;
    csv += `Pending from Customer,"${formatCurrencyCSV(stats.pendingReceived || 0)}"\n`;
    csv += `Pending to Vendors,"${formatCurrencyCSV(stats.pendingPayables || 0)}"\n`;

    const encodedUri = encodeURI(csv);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `Overall_Summary_${project?.name || 'Project'}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
};
