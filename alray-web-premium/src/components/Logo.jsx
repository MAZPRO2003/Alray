import React from 'react';

/**
 * AL RAY ASSOCIATES Logo
 * Matches the physical signage: gold AKA house icon + bold red "AL RAY ASSOCIATES" text
 */
const Logo = ({ className = "", showText = true, light = false, size = "md" }) => {
    const textColor = "#e01f26";       // Bold red (matches the sign)
    const goldColor = "#f5c000";       // Gold yellow (house + AKA + underline)
    const textShadowColor = light ? "none" : "1px 1px 0 rgba(255,255,255,0.15)";

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
