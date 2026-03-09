export function numberToWords(num) {
    if (num === 0) return 'Zero';

    const units = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];
    const teens = ['Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

    const convertLessThanOneThousand = (n) => {
        let str = '';
        if (n >= 100) {
            str += units[Math.floor(n / 100)] + ' Hundred ';
            n %= 100;
        }
        if (n >= 20) {
            str += tens[Math.floor(n / 10)] + ' ';
            n %= 10;
        }
        if (n >= 10) {
            str += teens[n - 10] + ' ';
            n = 0;
        }
        if (n > 0) {
            str += units[n] + ' ';
        }
        return str.trim();
    };

    let result = '';
    let remaining = Math.floor(num);

    // Crores
    if (remaining >= 10000000) {
        result += convertLessThanOneThousand(Math.floor(remaining / 10000000)) + ' Crore ';
        remaining %= 10000000;
    }

    // Lakhs
    if (remaining >= 100000) {
        result += convertLessThanOneThousand(Math.floor(remaining / 100000)) + ' Lakh ';
        remaining %= 100000;
    }

    // Thousands
    if (remaining >= 1000) {
        result += convertLessThanOneThousand(Math.floor(remaining / 1000)) + ' Thousand ';
        remaining %= 1000;
    }

    // Units
    if (remaining > 0) {
        result += convertLessThanOneThousand(remaining);
    }

    return result.trim() + ' Only';
}
