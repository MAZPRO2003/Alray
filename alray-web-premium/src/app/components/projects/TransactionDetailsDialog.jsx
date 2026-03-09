import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Download } from 'lucide-react';
import { receiptGenerator } from '../../utils/receiptGenerator';

export default function TransactionDetailsDialog({ isOpen, onClose, transaction, projectName }) {
    if (!isOpen || !transaction) return null;

    const isRevenue = transaction.transactionType === 'credit';

    // Formatting utils matching Flutter CurrencyUtils
    const formatInr = (amount) => {
        if (!amount) return '₹0';
        // Basic formatting, assumes global CurrencyUtils available or uses simple locale string
        const useIndianSystem = localStorage.getItem('indian_system') !== 'false';
        if (useIndianSystem) {
            return new Intl.NumberFormat('en-IN', {
                style: 'currency',
                currency: 'INR',
                maximumFractionDigits: 0
            }).format(amount);
        } else {
            return new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: 'INR',
                maximumFractionDigits: 0
            }).format(amount);
        }
    };

    const formatDate = (dateInput) => {
        if (!dateInput) return '';
        // Handle Firebase Timestamp or Date objects or strings
        const date = dateInput.toDate ? dateInput.toDate() : new Date(dateInput);
        return date.toLocaleDateString('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    };

    const _getExpenseColor = () => {
        if (transaction.categoryId?.endsWith('-M') || transaction.categoryId === 'Other Misc Materials') return 'text-green-600 bg-green-50';
        if (transaction.categoryId?.endsWith('-L') || transaction.categoryId === 'Plan Approval') return 'text-orange-600 bg-orange-50';
        return 'text-blue-600 bg-blue-50';
    };

    const _getExpenseTitle = () => {
        if (transaction.categoryId?.endsWith('-M') || transaction.categoryId === 'Other Misc Materials') return 'Material';
        if (transaction.categoryId?.endsWith('-L') || transaction.categoryId === 'Plan Approval') return 'Workers';
        return 'Custom';
    };

    const colorClass = isRevenue ? 'text-blue-600 bg-blue-50' : _getExpenseColor();
    const title = isRevenue ? 'Customer Payment' : _getExpenseTitle();

    const DetailRow = ({ label, value, isBold, valueColorClass }) => (
        <div className="py-2 flex flex-col items-start">
            <span className="text-xs font-medium text-gray-500 mb-0.5">{label}</span>
            <span className={`text-[15px] ${isBold ? 'font-bold' : 'font-medium'} ${valueColorClass || 'text-gray-900'}`}>
                {value}
            </span>
        </div>
    );

    return (
        <AnimatePresence>
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
                <motion.div
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    className="bg-white rounded-3xl shadow-xl w-full max-w-md overflow-hidden flex flex-col max-h-[90vh]"
                >
                    <div className="p-6 overflow-y-auto">
                        <div className="flex items-center justify-between mb-4">
                            <h2 className="text-xl font-bold text-[var(--color-primary)]">Transaction Details</h2>
                            <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded-full transition-colors">
                                <X size={20} className="text-gray-500" />
                            </button>
                        </div>

                        <hr className="mb-4 border-gray-100" />

                        <div className="space-y-1">
                            <DetailRow label="Project" value={projectName} />

                            <div className="py-2 flex flex-col items-start">
                                <span className="text-xs font-medium text-gray-500 mb-0.5">Type</span>
                                <span className={`text-[15px] font-medium px-2 py-0.5 rounded ${colorClass}`}>
                                    {title}
                                </span>
                            </div>

                            <DetailRow label="Date" value={formatDate(transaction.date)} />
                            <DetailRow
                                label="Amount"
                                value={formatInr(transaction.amount)}
                                isBold
                                valueColorClass={isRevenue ? 'text-blue-500' : 'text-red-500'}
                            />

                            {isRevenue && transaction.receiverName && (
                                <DetailRow label="Received From" value={transaction.receiverName} />
                            )}

                            {isRevenue && transaction.receiptNumber && (
                                <DetailRow label="Receipt Number" value={transaction.receiptNumber} />
                            )}

                            <DetailRow label="Description" value={transaction.description} />

                            {/* Expense Specific */}
                            {!isRevenue && (
                                <>
                                    <DetailRow label="Category" value={transaction.categoryId} />
                                    {transaction.quantity && transaction.quantity !== 1.0 && (
                                        <>
                                            <DetailRow label="Quantity" value={Number(transaction.quantity).toFixed(2)} />
                                            <DetailRow label="Rate" value={formatInr(transaction.rate)} />
                                        </>
                                    )}
                                    <DetailRow label="Payment Mode" value={String(transaction.paymentMode || 'cash').toUpperCase()} />
                                    {transaction.paymentMode === 'cheque' && transaction.referenceData && (
                                        <DetailRow label="Cheque Details" value={transaction.referenceData} />
                                    )}
                                </>
                            )}

                            {/* Revenue Specific */}
                            {isRevenue && (
                                <>
                                    <DetailRow label="Payment Mode" value={String(transaction.paymentMode || 'cash').toUpperCase()} />
                                    {transaction.paymentMode !== 'cash' && (
                                        <>
                                            {transaction.referenceData && (
                                                <DetailRow
                                                    label={transaction.paymentMode === 'cheque' ? 'Cheque No.' : 'TXN ID'}
                                                    value={transaction.referenceData}
                                                />
                                            )}
                                            {transaction.paymentDate && (
                                                <DetailRow label="Value Date" value={formatDate(transaction.paymentDate)} />
                                            )}
                                            {transaction.bankName && (
                                                <DetailRow label="Bank" value={transaction.bankName} />
                                            )}
                                            {transaction.branchName && (
                                                <DetailRow label="Branch" value={transaction.branchName} />
                                            )}
                                        </>
                                    )}
                                </>
                            )}
                        </div>

                        <div className="mt-8 flex gap-3">
                            {isRevenue && (
                                <button
                                    onClick={() => receiptGenerator.generate(transaction)}
                                    className="flex-1 px-4 py-3 flex items-center justify-center gap-2 border border-gray-200 text-[var(--color-primary)] font-bold rounded-xl hover:bg-gray-50 transition-colors"
                                >
                                    <Download size={18} />
                                    Receipt
                                </button>
                            )}
                            <button
                                onClick={onClose}
                                className="flex-1 px-4 py-3 bg-[var(--color-primary)] text-white font-bold rounded-xl hover:bg-opacity-90 transition-opacity"
                            >
                                Close
                            </button>
                        </div>
                    </div>
                </motion.div>
            </div>
        </AnimatePresence>
    );
}
