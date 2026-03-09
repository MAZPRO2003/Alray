import React from 'react';
import { Share, Home } from 'lucide-react';

export default function BusinessCard({ onClose }) {

    const handleShare = async () => {
        // In a real web app, we'd use html2canvas to capture this div and share it
        // For now we'll just show an alert or use the Web Share API if available
        if (navigator.share) {
            try {
                await navigator.share({
                    title: 'Al Ray Associates - Business Card',
                    text: 'Contact H.Abdul Kader - Managing Director, Al Ray Associates',
                    url: 'https://alray.in'
                });
            } catch (error) {
                console.error('Error sharing:', error);
            }
        } else {
            alert('Sharing is not supported on this browser.');
        }
    };

    return (
        <div className="fixed inset-0 bg-black/50 z-[100] flex items-center justify-center p-4">
            <div className="bg-white rounded-[20px] max-w-[650px] w-full overflow-hidden shadow-2xl flex flex-col">

                {/* Scrollable Container so it works on small screens */}
                <div className="overflow-auto p-4 flex justify-center bg-slate-50 relative">
                    {/* The Card Itself - Fixed Aspect Ratio/Size for consistency */}
                    <div
                        id="business-card-element"
                        className="bg-white rounded-[16px] shadow-sm shrink-0 flex flex-col justify-between overflow-hidden"
                        style={{
                            width: '600px',
                            height: '340px',
                            padding: '24px 32px',
                            border: '1px solid #e2e8f0',
                            boxShadow: '0 4px 10px rgba(0,0,0,0.05)'
                        }}
                    >
                        {/* --- HEADER --- */}
                        <div className="flex items-end gap-6 h-[80px]">
                            {/* House Logo Area */}
                            <div className="bg-[#DD2C33] px-2 py-1.5 rounded-t-sm flex flex-col items-center justify-center shrink-0 w-[50px]">
                                <Home color="white" size={32} fill="white" />
                                <span className="text-white font-bold text-[11px] tracking-[2px] font-montserrat mt-1">
                                    A R A
                                </span>
                            </div>

                            {/* Company Name */}
                            <div className="flex-1 pb-1">
                                <h1 className="text-[#DD2C33] text-[64px] font-black leading-[0.8]" style={{ fontFamily: "'Dancing Script', cursive" }}>
                                    Al Ray Associates
                                </h1>
                            </div>
                        </div>

                        {/* --- BODY --- */}
                        <div className="flex items-start mt-4 flex-1">
                            {/* Left Column: Name & Title */}
                            <div className="w-[45%] flex flex-col pt-1">
                                <h2 className="text-black text-[22px] font-black tracking-[-0.02em] leading-tight font-inter">
                                    H.ABDUL KADER
                                </h2>
                                <p className="text-gray-800 text-[16px] font-semibold mt-1 font-inter">
                                    Managing Director
                                </p>
                            </div>

                            {/* Right Column: Contact Details */}
                            <div className="w-[55%] flex flex-col gap-1 pt-1 ml-2">
                                <p className="text-black text-[14px] font-black tracking-[-0.01em] font-inter">
                                    1/1245, 1st Floor, West Main Road,
                                </p>
                                <p className="text-black text-[14px] font-black tracking-[-0.01em] font-inter">
                                    Kumudham Nagar Annex, Mugalivakkam,
                                </p>
                                <p className="text-black text-[14px] font-black tracking-[-0.01em] font-inter">
                                    Chennai - 600 125.
                                </p>

                                <div className="mt-2 space-y-1">
                                    <p className="text-black text-[14px] font-black tracking-[-0.01em] font-inter">
                                        Mobile: 8667011700 / 9841324123
                                    </p>
                                    <p className="text-black text-[14px] font-black tracking-[-0.01em] font-inter">
                                        E-mail: alrayassociates@gmail.com
                                    </p>
                                    <p className="text-black text-[14px] font-black tracking-[-0.01em] font-inter">
                                        Website: <span className="text-blue-600 underline cursor-pointer" onClick={() => window.open('https://www.alray.in', '_blank')}>www.alray.in</span>
                                    </p>
                                </div>
                            </div>
                        </div>

                        {/* --- FOOTER --- */}
                        <div className="flex justify-center mb-1">
                            <p className="text-black text-[20px] font-black tracking-[0.01em] font-inter">
                                Plan / Estimate / Construction / Real Estate
                            </p>
                        </div>
                    </div>
                </div>

                {/* --- UI ACTIONS --- */}
                <div className="p-4 px-6 border-t border-slate-100 flex items-center justify-between bg-white shrink-0 shadow-[0_-4px_20px_rgba(0,0,0,0.02)]">
                    <button
                        onClick={onClose}
                        className="px-5 py-2.5 text-slate-500 font-bold hover:bg-slate-50 rounded-xl transition-colors text-sm"
                    >
                        Close
                    </button>

                    <button
                        onClick={handleShare}
                        className="px-6 py-2.5 bg-[#DD2C33] hover:bg-[#C5272E] text-white font-bold rounded-xl transition-colors shadow-sm flex items-center gap-2 text-sm"
                    >
                        <Share size={16} />
                        Share Details
                    </button>
                </div>
            </div>

            {/* Inject fonts if not already available in index.html */}
            <style dangerouslySetInnerHTML={{
                __html: `
                @import url('https://fonts.googleapis.com/css2?family=Dancing+Script:wght@700..900&family=Inter:wght@600;800;900&family=Montserrat:wght@700&display=swap');
                .font-montserrat { font-family: 'Montserrat', sans-serif; }
                .font-inter { font-family: 'Inter', sans-serif; }
            `}} />
        </div>
    );
}
