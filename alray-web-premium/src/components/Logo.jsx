import React from 'react';

/**
 * AL RAY ASSOCIATES Logo
 * Matches the physical signage: gold AKA house icon + bold red "AL RAY ASSOCIATES" text
 */
const Logo = ({ className = "", showText = true, light = false, size = "md" }) => {
    const textColor = light ? "#ffffff" : "#0a113d";    // White text at top, Deep Navy scrolled
    const goldColor = light ? "#fcc201" : "#D4AF37";    // Bright Gold at top, Premium Gold scrolled
    const textShadowColor = light ? "0 2px 4px rgba(0,0,0,0.2)" : "none";

    const sizes = {
        sm: { icon: 36, title: 16, sub: 10 },
        md: { icon: 52, title: 24, sub: 14 },
        lg: { icon: 70, title: 32, sub: 18 },
    };
    const s = sizes[size] || sizes.md;

    return (
        <div
            className={className}
            style={{ display: 'flex', alignItems: 'center', gap: '10px' }}
        >
            {/* ── AKA House Icon ── */}
            <svg
                width={s.icon}
                height={s.icon}
                viewBox="0 0 100 110"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
            >
                {/* Roof / Chevron */}
                <path
                    d="M8 46L50 10L92 46"
                    stroke={goldColor}
                    strokeWidth="9"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    fill="none"
                />

                {/* House body outline */}
                <path
                    d="M22 46V80H78V46"
                    stroke={goldColor}
                    strokeWidth="5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    fill="none"
                />



                {/* "ARA" text */}
                <text
                    x="50"
                    y="72"
                    textAnchor="middle"
                    fill={goldColor}
                    style={{
                        fontSize: '17px',
                        fontWeight: 'bold',
                        fontFamily: 'Georgia, serif',
                        letterSpacing: '2px',
                    }}
                >
                    ARA
                </text>

                {/* Decorative underline swoosh below ARA */}
                <path
                    d="M22 78 Q50 86 78 78"
                    stroke={goldColor}
                    strokeWidth="3"
                    strokeLinecap="round"
                    fill="none"
                />
            </svg>

            {/* ── Brand Text ── */}
            {showText && (
                <div style={{ display: 'flex', flexDirection: 'column', lineHeight: '1.05' }}>
                    <span
                        style={{
                            color: textColor,
                            fontSize: `${s.title}px`,
                            fontWeight: '900',
                            fontFamily: "'Playfair Display', Georgia, serif",
                            letterSpacing: '2px',
                            textShadow: textShadowColor,
                        }}
                    >
                        AL RAY
                    </span>
                    <span
                        style={{
                            color: textColor,
                            fontSize: `${s.sub}px`,
                            fontWeight: '800',
                            fontFamily: "'Outfit', 'Arial', sans-serif",
                            letterSpacing: '3.5px',
                            marginTop: '1px',
                        }}
                    >
                        ASSOCIATES
                    </span>
                </div>
            )}
        </div>
    );
};

export default Logo;
