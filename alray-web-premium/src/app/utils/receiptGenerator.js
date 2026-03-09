import { jsPDF } from 'jspdf';
import { numberToWords } from './numberToWords';

export const receiptGenerator = {
    generate: (entry) => {
        // Create PDF with custom size matching Flutter version: 21cm x 16cm
        // jspdf uses mm by default
        const doc = new jsPDF({
            orientation: 'landscape',
            unit: 'mm',
            format: [210, 160]
        });

        const formatDate = (dateStr) => {
            if (!dateStr) return '';
            const date = new Date(dateStr);
            return `${date.getDate().toString().padStart(2, '0')}/${(date.getMonth() + 1).toString().padStart(2, '0')}/${date.getFullYear()}`;
        };

        const dateStr = formatDate(entry.date);
        const pDateStr = entry.paymentDate ? formatDate(entry.paymentDate) : dateStr;

        // Colors
        const primaryColor = [13, 71, 161]; // blueGrey900 approx
        const accentColor = [13, 71, 161]; // blue900

        // External Border
        doc.setLineWidth(1);
        doc.setDrawColor(33, 33, 33);
        doc.rect(5, 5, 200, 150);

        // Header
        doc.setFont('helvetica', 'bold');
        doc.setFontSize(28);
        doc.setTextColor(accentColor[0], accentColor[1], accentColor[2]);
        doc.text('AL RAY ASSOCIATES', 105, 25, { align: 'center' });

        doc.setFontSize(14);
        doc.text('ENGINEER & BUILDER', 105, 33, { align: 'center' });

        doc.setFont('helvetica', 'normal');
        doc.setFontSize(10);
        doc.text('1/1245, 1ST FLOOR, AIR INDIA COLONY, KUMUDHAM NAGAR,', 105, 40, { align: 'center' });
        doc.text('MUGALIVAKKAM, Chennai-600 125.', 105, 45, { align: 'center' });

        // Receipt No & Date
        doc.setFont('helvetica', 'bold');
        doc.setFontSize(12);
        doc.setTextColor(0, 0, 0);
        doc.text('No: ', 15, 60);
        doc.setFont('helvetica', 'normal');
        doc.text(entry.receiptNumber || '-', 25, 60);

        doc.setFont('helvetica', 'bold');
        doc.text('Date : ', 150, 60);
        doc.setFont('helvetica', 'normal');
        doc.text(dateStr, 165, 60);
        doc.line(164, 61, 190, 61); // Underline date

        // Content
        const drawLineItem = (label, value, y) => {
            doc.setFont('helvetica', 'bold');
            doc.setFontSize(12);
            doc.text(label, 15, y);

            const labelWidth = doc.getTextWidth(label);
            doc.setFont('helvetica', 'normal');
            doc.text(String(value || '-'), 15 + labelWidth + 2, y);

            // Dotted underline
            doc.setLineDash([0.5, 0.5]);
            doc.line(15 + labelWidth + 1, y + 1, 195, y + 1);
            doc.setLineDash([]);
        };

        drawLineItem('RECEIVED with thanks from Mr.', entry.receiverName, 75);
        drawLineItem('the sum of Rupees', entry.amountInWords || numberToWords(entry.amount), 85);

        if (entry.bank) {
            drawLineItem('Bank: ', entry.bank, 95);
        }

        // Row with multiple items
        const yContact = entry.bank ? 105 : 95;
        doc.setFont('helvetica', 'bold');
        doc.text('By Cash / Draft / Cheque No: ', 15, yContact);
        let currentX = 15 + doc.getTextWidth('By Cash / Draft / Cheque No: ') + 2;
        doc.setFont('helvetica', 'normal');
        doc.text(entry.referenceData || '-', currentX, yContact);
        doc.setLineDash([0.5, 0.5]);
        doc.line(currentX - 1, yContact + 1, currentX + 40, yContact + 1);

        currentX += 45;
        doc.setFont('helvetica', 'bold');
        doc.text('Dated: ', currentX, yContact);
        currentX += doc.getTextWidth('Dated: ') + 2;
        doc.setFont('helvetica', 'normal');
        doc.text(pDateStr, currentX, yContact);
        doc.line(currentX - 1, yContact + 1, currentX + 30, yContact + 1);
        doc.setLineDash([]);

        const yDrawnOn = yContact + 10;
        doc.setFont('helvetica', 'bold');
        doc.text('Drawn On: ', 15, yDrawnOn);
        currentX = 15 + doc.getTextWidth('Drawn On: ') + 2;
        doc.setFont('helvetica', 'normal');
        doc.text(entry.bankName || '-', currentX, yDrawnOn);
        doc.setLineDash([0.5, 0.5]);
        doc.line(currentX - 1, yDrawnOn + 1, currentX + 50, yDrawnOn + 1);

        currentX += 55;
        doc.setFont('helvetica', 'bold');
        doc.text('Branch: ', currentX, yDrawnOn);
        currentX += doc.getTextWidth('Branch: ') + 2;
        doc.setFont('helvetica', 'normal');
        doc.text(entry.branchName || '-', currentX, yDrawnOn);
        doc.line(currentX - 1, yDrawnOn + 1, 195, yDrawnOn + 1);
        doc.setLineDash([]);

        drawLineItem('Towards Construction works:', entry.description, yDrawnOn + 10);

        // Footer
        const footerY = 140;
        // Amount Box
        doc.setLineWidth(0.5);
        doc.rect(15, footerY - 8, 50, 12);
        doc.setFont('helvetica', 'bold');
        doc.setFontSize(18);
        const amountStr = `Rs.${new Intl.NumberFormat('en-IN').format(entry.amount)}/-`;
        doc.text(amountStr, 40, footerY, { align: 'center' });

        // Signature
        doc.setFontSize(10);
        doc.setTextColor(accentColor[0], accentColor[1], accentColor[2]);
        doc.text('For Al Ray Associates', 170, footerY - 15, { align: 'center' });
        doc.setFontSize(12);
        doc.text('H. Abdul Kader', 170, footerY, { align: 'center' });

        // Save
        doc.save(`Receipt_${entry.receiptNumber || entry.id}.pdf`);
    }
};
