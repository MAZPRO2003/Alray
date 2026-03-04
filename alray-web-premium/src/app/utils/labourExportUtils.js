import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';

const formatDate = (date) => {
    if (!date) return '—';
    const d = date.toDate ? date.toDate() : new Date(date);
    return d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
};

const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-IN', {
        style: 'currency', currency: 'INR', maximumFractionDigits: 0
    }).format(amount || 0);
};

export const generateLabourPDF = (project, tasks, payments, mode = 'combined') => {
    const doc = new jsPDF();
    const primaryColor = [31, 41, 55]; // slate-800
    const secondaryColor = [249, 115, 22]; // orange-500

    // Header
    doc.setFontSize(22);
    doc.setTextColor(...primaryColor);
    doc.text('Alray Associates', 14, 20);

    doc.setFontSize(14);
    doc.setTextColor(...secondaryColor);

    let reportTitle = 'Labour Management Report';
    if (mode === 'tasks') reportTitle = 'Labour Task Management';
    if (mode === 'payments') reportTitle = 'Labour Weekly Payments';
    doc.text(reportTitle, 14, 30);

    // Project Info
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Project: ${project?.name || 'N/A'}`, 14, 40);
    doc.text(`Client: ${project?.clientName || 'N/A'}`, 14, 45);
    doc.text(`Location: ${project?.location || 'N/A'}`, 14, 50);
    doc.text(`Date Generated: ${formatDate(new Date())}`, 14, 55);

    let startY = 65;

    // Summary (Only for payments or combined)
    if (mode === 'payments' || mode === 'combined') {
        const totalSpent = payments.reduce((sum, p) => sum + (p.amount || 0), 0);
        doc.setFontSize(12);
        doc.setTextColor(...primaryColor);
        doc.text(`Total Labour Spent: ${formatCurrency(totalSpent)}`, 14, startY);
        startY += 10;
    }

    // Tasks Table
    if ((mode === 'tasks' || mode === 'combined') && tasks && tasks.length > 0) {
        doc.setFontSize(14);
        doc.setTextColor(...primaryColor);
        doc.text('Labor Tasks', 14, startY);
        startY += 5;

        const taskRows = tasks.map(t => [
            t.name,
            t.role,
            t.laborerCount,
            `${Math.round((t.completionPercentage || 0) * 100)}%`,
            formatDate(t.startDate),
            t.durationInDays || 0
        ]);

        autoTable(doc, {
            startY: startY,
            head: [['Task Name', 'Role', 'Laborers', 'Progress', 'Start Date', 'Days']],
            body: taskRows,
            theme: 'striped',
            headStyles: { fillColor: secondaryColor },
            styles: { fontSize: 9 },
        });

        startY = doc.lastAutoTable.finalY + 15;
    }

    // Payments Table
    if ((mode === 'payments' || mode === 'combined') && payments && payments.length > 0) {
        doc.setFontSize(14);
        doc.setTextColor(...primaryColor);
        doc.text('Weekly Payments', 14, startY);
        startY += 5;

        const paymentRows = payments.map(p => [
            p.laborerName,
            formatDate(p.periodStart),
            formatDate(p.periodEnd),
            p.description || '-',
            formatCurrency(p.amount)
        ]);

        autoTable(doc, {
            startY: startY,
            head: [['Laborer / Group', 'Period Start', 'Period End', 'Description', 'Amount']],
            body: paymentRows,
            theme: 'striped',
            headStyles: { fillColor: secondaryColor },
            styles: { fontSize: 9 },
        });
    }

    doc.save(`Labour_${mode}_${project?.name?.replace(/\s+/g, '_') || 'Project'}.pdf`);
};

export const generateLabourCSV = (project, tasks, payments, mode = 'combined') => {
    let csvContent = "data:text/csv;charset=utf-8,";

    // Project Info
    csvContent += "PROJECT INFORMATION\n";
    csvContent += `Project Name,${project?.name || 'N/A'}\n`;
    csvContent += `Client,${project?.clientName || 'N/A'}\n`;
    csvContent += `Location,${project?.location || 'N/A'}\n`;

    if (mode === 'payments' || mode === 'combined') {
        const totalSpent = payments.reduce((sum, p) => sum + (p.amount || 0), 0);
        csvContent += `Total Labour Spent,${totalSpent}\n`;
    }
    csvContent += "\n";

    // Tasks
    if (mode === 'tasks' || mode === 'combined') {
        csvContent += "LABOR TASKS\n";
        csvContent += "Task Name,Role,Laborers,Progress (%),Start Date,Duration (Days)\n";
        tasks.forEach(t => {
            const row = [
                `"${t.name || ''}"`,
                `"${t.role || ''}"`,
                t.laborerCount || 0,
                Math.round((t.completionPercentage || 0) * 100),
                `"${formatDate(t.startDate)}"`,
                t.durationInDays || 0
            ].join(",");
            csvContent += row + "\n";
        });
        csvContent += "\n";
    }

    // Payments
    if (mode === 'payments' || mode === 'combined') {
        csvContent += "WEEKLY PAYMENTS\n";
        csvContent += "Laborer / Group,Period Start,Period End,Description,Amount\n";
        payments.forEach(p => {
            const row = [
                `"${p.laborerName || ''}"`,
                `"${formatDate(p.periodStart)}"`,
                `"${formatDate(p.periodEnd)}"`,
                `"${p.description || ''}"`,
                p.amount || 0
            ].join(",");
            csvContent += row + "\n";
        });
    }

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `Labour_${mode}_${project?.name?.replace(/\s+/g, '_') || 'Project'}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
};
