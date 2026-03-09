import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';

const formatDate = (date) => {
    if (!date) return '—';
    const d = date.toDate ? date.toDate() : new Date(date);
    return d.toLocaleDateString('en-GB', { day: '2-digit', month: '2-digit', year: 'numeric' });
};

const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-IN', {
        style: 'currency', currency: 'INR', maximumFractionDigits: 0
    }).format(amount || 0);
};

// Extracted worker roles
const roles = [
    { key: 'mason', title: 'mason', countKey: 'mason', rateKey: 'masonRate' },
    { key: 'helper', title: 'Helper', countKey: 'helper', rateKey: 'helperRate' },
    { key: 'plumber', title: 'Plumber', countKey: 'plumber', rateKey: 'plumberRate' },
    { key: 'electrician', title: 'Electrician', countKey: 'electrician', rateKey: 'electricianRate' },
    { key: 'carpenter', title: 'carpenter', countKey: 'carpenter', rateKey: 'carpenterRate' },
    { key: 'steelWorker', title: 'steel\nworker', countKey: 'steelWorker', rateKey: 'steelWorkerRate' },
    { key: 'grillWorker', title: 'grill\nworker', countKey: 'grillWorker', rateKey: 'grillWorkerRate' },
    { key: 'tileLabour', title: 'tile\nlabour', countKey: 'tileLabour', rateKey: 'tileLabourRate' },
    { key: 'painter', title: 'painter', countKey: 'painter', rateKey: 'painterRate' },
    { key: 'custom', title: 'Custom', countKey: 'customEntered', rateKey: 'customEnteredRate' },
    { key: 'others', title: 'others', countKey: 'others', rateKey: 'othersRate' }
];

const getCellStr = (count, rate, name) => {
    if (!count || count === 0) return '-';
    let r = Math.round(rate || 0).toString();
    const val = `${count}\n${r}rs`;
    return (!name) ? val : `${name}\n${val}`;
};

const getCsvCellStr = (count, rate, name) => {
    if (!count || count === 0) return '';
    if (!rate || rate === 0) return `${count}`;
    let r = Math.round(rate).toString();
    const val = `${count}- ${r}rs`;
    return (!name) ? val : `${name}: ${val}`;
};

const calculateTotals = (recordList) => {
    let workers = 0;
    let cost = 0;
    recordList.forEach(r => {
        roles.forEach(role => {
            if (role.key !== 'custom') {
                workers += (r[role.countKey] || 0);
                cost += (r[role.countKey] || 0) * (r[role.rateKey] || 0);
            }
        });
        workers += (r.customEntered || 0);
        cost += (r.customEntered || 0) * (r.customEnteredRate || 0);
    });
    return { workers, cost };
};


export const generateAttendancePDF = (project, records, isWeekly = false, weekStart = null, weekEnd = null) => {
    const getUniqueCustomName = (records) => {
        const customRecords = records.filter(r => (r.customEntered || 0) > 0 && r.customRoleName);
        const uniqueNames = [...new Set(customRecords.map(r => r.customRoleName))];
        return uniqueNames.length === 1 ? uniqueNames[0] : null;
    };

    const uniqueCustomName = getUniqueCustomName(records);

    // Landscape orientation
    const doc = new jsPDF('landscape');
    const primaryColor = [31, 41, 55]; // slate-800
    const headerColor = [21, 101, 192]; // #1565C0 from Flutter

    // Title
    doc.setFontSize(16);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(...primaryColor);

    let titleStr = `Attendance Register - ${project?.name || 'Project'}`;
    let subtitleStr = `Generated: ${new Date().toLocaleDateString('en-GB')}`;

    if (isWeekly && weekStart && weekEnd) {
        titleStr = `Weekly Attendance - ${project?.name || 'Project'}`;
        subtitleStr = `Week: ${weekStart.toLocaleDateString('en-GB')} - ${weekEnd.toLocaleDateString('en-GB')}`;
    }

    doc.text(titleStr, 24, 24);

    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(117, 117, 117); // grey600
    doc.text(subtitleStr, 24, 30);

    const totals = calculateTotals(records);

    let startY = 40;

    if (records && records.length > 0) {
        // Headers matching Flutter exactly
        const tableHeaders = [
            'Date', ...roles.map(r => {
                if (r.key === 'custom' && uniqueCustomName) return uniqueCustomName;
                return r.title;
            }), 'Total\nWorkers', 'Total\nCost (Rs)'
        ];

        const rows = records.map(r => {
            return [
                formatDate(r.date),
                getCellStr(r.mason, r.masonRate),
                getCellStr(r.helper, r.helperRate),
                getCellStr(r.plumber, r.plumberRate),
                getCellStr(r.electrician, r.electricianRate),
                getCellStr(r.carpenter, r.carpenterRate),
                getCellStr(r.steelWorker, r.steelWorkerRate),
                getCellStr(r.grillWorker, r.grillWorkerRate),
                getCellStr(r.tileLabour, r.tileLabourRate),
                getCellStr(r.painter, r.painterRate),
                getCellStr(r.customEntered, r.customEnteredRate, r.customRoleName),
                getCellStr(r.others, r.othersRate),
                (r.mason || 0) + (r.helper || 0) + (r.plumber || 0) + (r.electrician || 0) + (r.carpenter || 0) + (r.steelWorker || 0) + (r.grillWorker || 0) + (r.tileLabour || 0) + (r.painter || 0) + (r.customEntered || 0) + (r.others || 0),
                r.mason * r.masonRate + r.helper * r.helperRate + r.plumber * r.plumberRate + r.electrician * r.electricianRate + r.carpenter * r.carpenterRate + r.steelWorker * r.steelWorkerRate + r.grillWorker * r.grillWorkerRate + r.tileLabour * r.tileLabourRate + r.painter * r.painterRate + r.customEntered * r.customEnteredRate + r.others * r.othersRate > 0 ?
                    `Rs.${new Intl.NumberFormat('en-IN').format(r.mason * r.masonRate + r.helper * r.helperRate + r.plumber * r.plumberRate + r.electrician * r.electricianRate + r.carpenter * r.carpenterRate + r.steelWorker * r.steelWorkerRate + r.grillWorker * r.grillWorkerRate + r.tileLabour * r.tileLabourRate + r.painter * r.painterRate + r.customEntered * r.customEnteredRate + r.others * r.othersRate)}` : '-'
            ];
        });

        autoTable(doc, {
            startY: startY,
            head: [tableHeaders],
            body: rows,
            theme: 'striped',
            headStyles: {
                fillColor: headerColor,
                textColor: 255,
                fontSize: 8,
                fontStyle: 'bold',
                halign: 'center',
                valign: 'middle',
                lineWidth: 0.1,
                lineColor: 200
            },
            styles: {
                fontSize: 8,
                halign: 'center',
                valign: 'middle',
                cellPadding: 2,
                lineWidth: 0.1,
                lineColor: 200
            },
            alternateRowStyles: {
                fillColor: [245, 245, 245] // #F5F5F5
            },
            columnStyles: {
                0: { cellWidth: 20 }, // Date
                11: { cellWidth: 15 }, // Total workers
                12: { cellWidth: 25 }  // Total cost
            },
            margin: { left: 24, right: 24, bottom: 30 }
        });

        const finalY = doc.lastAutoTable.finalY;

        // Footer Totals Row
        doc.setFontSize(9);
        doc.setFont('helvetica', 'bold');
        doc.setTextColor(0);

        let footerStr = `${records.length} day(s)  |  ${totals.workers} workers  |  `;
        if (totals.cost > 0) {
            footerStr += `Total: Rs.${new Intl.NumberFormat('en-IN').format(totals.cost)}`;
        }

        doc.text(footerStr, doc.internal.pageSize.width - 24, finalY + 8, { align: 'right' });
    }

    const fname = isWeekly ? `WeeklyAttendance_${project?.name?.replace(/\s+/g, '_')}_${Date.now()}.pdf` : `Attendance_${project?.name?.replace(/\s+/g, '_')}_${Date.now()}.pdf`;
    doc.save(fname);
};

export const generateAttendanceCSV = (project, records, isWeekly = false, weekStart = null, weekEnd = null) => {
    let csvContent = "data:text/csv;charset=utf-8,";

    if (isWeekly && weekStart && weekEnd) {
        csvContent += `Project: ${project?.name || 'N/A'}\n`;
        csvContent += `Week: ${weekStart.toLocaleDateString('en-GB')} - ${weekEnd.toLocaleDateString('en-GB')}\n\n`;
    }

    const getUniqueCustomName = (records) => {
        const customRecords = records.filter(r => (r.customEntered || 0) > 0 && r.customRoleName);
        const uniqueNames = [...new Set(customRecords.map(r => r.customRoleName))];
        return uniqueNames.length === 1 ? uniqueNames[0] : null;
    };

    const uniqueCustomName = getUniqueCustomName(records);

    const csvHeaders = [
        'Date', 'mason', 'Helper', 'Plumber', 'Electrician', 'carpenter',
        'steel worker', 'grill worker', 'tile labour', 'painter', uniqueCustomName || 'Custom', 'others',
        'Total Workers', 'Total Cost (Rs)', 'Notes'
    ];

    csvContent += csvHeaders.join(',') + "\n";

    records.forEach(r => {
        const row = [
            `"${formatDate(r.date)}"`,
            `"${getCsvCellStr(r.mason, r.masonRate)}"`,
            `"${getCsvCellStr(r.helper, r.helperRate)}"`,
            `"${getCsvCellStr(r.plumber, r.plumberRate)}"`,
            `"${getCsvCellStr(r.electrician, r.electricianRate)}"`,
            `"${getCsvCellStr(r.carpenter, r.carpenterRate)}"`,
            `"${getCsvCellStr(r.steelWorker, r.steelWorkerRate)}"`,
            `"${getCsvCellStr(r.grillWorker, r.grillWorkerRate)}"`,
            `"${getCsvCellStr(r.tileLabour, r.tileLabourRate)}"`,
            `"${getCsvCellStr(r.painter, r.painterRate)}"`,
            `"${getCsvCellStr(r.customEntered, r.customEnteredRate, r.customRoleName)}"`,
            `"${getCsvCellStr(r.others, r.othersRate)}"`,
            (r.mason || 0) + (r.helper || 0) + (r.plumber || 0) + (r.electrician || 0) + (r.carpenter || 0) + (r.steelWorker || 0) + (r.grillWorker || 0) + (r.tileLabour || 0) + (r.painter || 0) + (r.customEntered || 0) + (r.others || 0),
            r.mason * r.masonRate + r.helper * r.helperRate + r.plumber * r.plumberRate + r.electrician * r.electricianRate + r.carpenter * r.carpenterRate + r.steelWorker * r.steelWorkerRate + r.grillWorker * r.grillWorkerRate + r.tileLabour * r.tileLabourRate + r.painter * r.painterRate + r.customEntered * r.customEnteredRate + r.others * r.othersRate || 0,
            `"${r.notes || ''}"`
        ];
        csvContent += row.join(",") + "\n";
    });

    if (isWeekly) {
        const totals = calculateTotals(records);
        const totalRow = [
            `"TOTALS"`, '', '', '', '', '', '', '', '', '', '', totals.workers, totals.cost, ''
        ];
        csvContent += totalRow.join(",") + "\n";
    }

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);

    const fname = isWeekly ? `WeeklyAttendance_${project?.name?.replace(/\s+/g, '_')}_${Date.now()}.csv` : `Attendance_${project?.name?.replace(/\s+/g, '_')}_${Date.now()}.csv`;
    link.setAttribute("download", fname);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
};
