(globalThis["TURBOPACK"] || (globalThis["TURBOPACK"] = [])).push([typeof document === "object" ? document.currentScript : undefined,
"[project]/apps/admin/app/page.tsx [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>AdminDashboard
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/apps/admin/node_modules/next/dist/compiled/react/jsx-dev-runtime.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/apps/admin/node_modules/next/dist/compiled/react/index.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$lib$2f$api$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/apps/admin/lib/api.ts [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$lib$2f$security$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/apps/admin/lib/security.ts [app-client] (ecmascript)");
;
var _s = __turbopack_context__.k.signature();
"use client";
;
;
;
const numberFormatter = new Intl.NumberFormat("tr-TR");
const dateFormatter = new Intl.DateTimeFormat("tr-TR", {
    day: "2-digit",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit"
});
const navItems = [
    {
        label: "Genel bakış",
        icon: "grid",
        active: true
    },
    {
        label: "Kullanıcılar",
        icon: "users",
        count: "users"
    },
    {
        label: "Şikâyetler",
        icon: "flag",
        count: "reports"
    },
    {
        label: "İçerik kuyruğu",
        icon: "layers",
        count: "content"
    },
    {
        label: "Mesh sağlığı",
        icon: "pulse",
        count: "mesh"
    }
];
const emptyOverview = {
    generatedAt: "",
    users: {
        total: 0,
        active24h: 0,
        pendingVerification: 0,
        newThisWeek: 0
    },
    reports: {
        open: 0,
        urgent: 0,
        resolvedToday: 0,
        medianResponseMinutes: 0
    },
    content: {
        pendingReview: 0,
        removedToday: 0,
        flaggedMedia: 0,
        appeals: 0
    },
    mesh: {
        state: "offline",
        healthyNodes: 0,
        totalNodes: 0,
        averageLatencyMs: 0,
        lastSyncAt: ""
    },
    activity: []
};
function formatNumber(value) {
    return numberFormatter.format(value);
}
function formatTime(value) {
    if (!value) return "—";
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? value : dateFormatter.format(date);
}
function relativeTime(value) {
    if (!value) return "—";
    const elapsedMinutes = Math.max(0, Math.round((Date.now() - new Date(value).getTime()) / 60000));
    if (elapsedMinutes < 1) return "az önce";
    if (elapsedMinutes < 60) return `${elapsedMinutes} dk önce`;
    const elapsedHours = Math.round(elapsedMinutes / 60);
    return elapsedHours < 24 ? `${elapsedHours} sa önce` : `${Math.round(elapsedHours / 24)} gün önce`;
}
function Icon({ name }) {
    const common = {
        width: 20,
        height: 20,
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        strokeWidth: 1.8,
        strokeLinecap: "round",
        strokeLinejoin: "round"
    };
    if (name === "grid") return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
        ...common,
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("rect", {
                x: "3",
                y: "3",
                width: "7",
                height: "7",
                rx: "1"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 54,
                columnNumber: 48
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("rect", {
                x: "14",
                y: "3",
                width: "7",
                height: "7",
                rx: "1"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 54,
                columnNumber: 96
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("rect", {
                x: "3",
                y: "14",
                width: "7",
                height: "7",
                rx: "1"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 54,
                columnNumber: 145
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("rect", {
                x: "14",
                y: "14",
                width: "7",
                height: "7",
                rx: "1"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 54,
                columnNumber: 194
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/apps/admin/app/page.tsx",
        lineNumber: 54,
        columnNumber: 31
    }, this);
    if (name === "users") return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
        ...common,
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                d: "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 55,
                columnNumber: 49
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("circle", {
                cx: "9",
                cy: "7",
                r: "4"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 55,
                columnNumber: 103
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                d: "M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 55,
                columnNumber: 133
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/apps/admin/app/page.tsx",
        lineNumber: 55,
        columnNumber: 32
    }, this);
    if (name === "flag") return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
        ...common,
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                d: "M5 21V4"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 56,
                columnNumber: 48
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                d: "M5 4c5-3 9 3 14 0v10c-5 3-9-3-14 0"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 56,
                columnNumber: 68
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/apps/admin/app/page.tsx",
        lineNumber: 56,
        columnNumber: 31
    }, this);
    if (name === "layers") return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
        ...common,
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                d: "m12 2 9 5-9 5-9-5 9-5Z"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 57,
                columnNumber: 50
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                d: "m3 12 9 5 9-5"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 57,
                columnNumber: 85
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                d: "m3 17 9 5 9-5"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 57,
                columnNumber: 111
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/apps/admin/app/page.tsx",
        lineNumber: 57,
        columnNumber: 33
    }, this);
    if (name === "pulse") return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
        ...common,
        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
            d: "M3 12h4l3-8 4 16 3-8h4"
        }, void 0, false, {
            fileName: "[project]/apps/admin/app/page.tsx",
            lineNumber: 58,
            columnNumber: 49
        }, this)
    }, void 0, false, {
        fileName: "[project]/apps/admin/app/page.tsx",
        lineNumber: 58,
        columnNumber: 32
    }, this);
    if (name === "settings") return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
        ...common,
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("circle", {
                cx: "12",
                cy: "12",
                r: "3"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 59,
                columnNumber: 52
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                d: "M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-1.4 1.4-.06-.06a1.7 1.7 0 0 0-1.88-.34 1.7 1.7 0 0 0-1.03 1.56V21h-2v-.5a1.7 1.7 0 0 0-1.03-1.56 1.7 1.7 0 0 0-1.88.34l-.06.06-1.4-1.4.06-.06A1.7 1.7 0 0 0 9.4 15a1.7 1.7 0 0 0-1.56-1.03H7v-2h.5A1.7 1.7 0 0 0 9.06 11a1.7 1.7 0 0 0-.34-1.88l-.06-.06 1.4-1.4.06.06A1.7 1.7 0 0 0 12 8.06 1.7 1.7 0 0 0 13.03 6.5V6h2v.5A1.7 1.7 0 0 0 16.06 8a1.7 1.7 0 0 0 1.88-.34L18 7.6l1.4 1.4-.06.06A1.7 1.7 0 0 0 19.4 11c.17.62.75 1.03 1.39 1.03H21v2h-.21c-.64 0-1.22.4-1.39.97Z"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 59,
                columnNumber: 84
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/apps/admin/app/page.tsx",
        lineNumber: 59,
        columnNumber: 35
    }, this);
    if (name === "search") return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
        ...common,
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("circle", {
                cx: "11",
                cy: "11",
                r: "7"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 60,
                columnNumber: 50
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                d: "m20 20-4-4"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 60,
                columnNumber: 82
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/apps/admin/app/page.tsx",
        lineNumber: 60,
        columnNumber: 33
    }, this);
    if (name === "shield") return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
        ...common,
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                d: "M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 61,
                columnNumber: 50
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                d: "m9 12 2 2 4-4"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 61,
                columnNumber: 106
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/apps/admin/app/page.tsx",
        lineNumber: 61,
        columnNumber: 33
    }, this);
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
        ...common,
        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("circle", {
            cx: "12",
            cy: "12",
            r: "9"
        }, void 0, false, {
            fileName: "[project]/apps/admin/app/page.tsx",
            lineNumber: 62,
            columnNumber: 27
        }, this)
    }, void 0, false, {
        fileName: "[project]/apps/admin/app/page.tsx",
        lineNumber: 62,
        columnNumber: 10
    }, this);
}
_c = Icon;
function healthLabel(state) {
    return state === "healthy" ? "Sağlıklı" : state === "degraded" ? "Kısmi sorun" : "Çevrimdışı";
}
function HealthPill({ state }) {
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
        className: `health-pill ${state}`,
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                className: "health-dot"
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 70,
                columnNumber: 51
            }, this),
            healthLabel(state)
        ]
    }, void 0, true, {
        fileName: "[project]/apps/admin/app/page.tsx",
        lineNumber: 70,
        columnNumber: 10
    }, this);
}
_c1 = HealthPill;
function MetricCard({ title, value, caption, icon, tone, footer }) {
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("article", {
        className: "metric-card",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: `metric-icon ${tone}`,
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(Icon, {
                    name: icon
                }, void 0, false, {
                    fileName: "[project]/apps/admin/app/page.tsx",
                    lineNumber: 76,
                    columnNumber: 46
                }, this)
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 76,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "metric-heading",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                        children: title
                    }, void 0, false, {
                        fileName: "[project]/apps/admin/app/page.tsx",
                        lineNumber: 77,
                        columnNumber: 39
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                        className: "metric-menu",
                        children: "•••"
                    }, void 0, false, {
                        fileName: "[project]/apps/admin/app/page.tsx",
                        lineNumber: 77,
                        columnNumber: 59
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 77,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                className: "metric-value",
                children: value
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 78,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "metric-caption",
                children: caption
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 79,
                columnNumber: 7
            }, this),
            footer && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "metric-footer",
                children: footer
            }, void 0, false, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 80,
                columnNumber: 18
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/apps/admin/app/page.tsx",
        lineNumber: 75,
        columnNumber: 5
    }, this);
}
_c2 = MetricCard;
function AdminDashboard() {
    _s();
    const [overview, setOverview] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(emptyOverview);
    const [loading, setLoading] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(true);
    const [error, setError] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(null);
    const [lastRefresh, setLastRefresh] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useState"])(null);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "AdminDashboard.useEffect": ()=>{
            let mounted = true;
            __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$lib$2f$api$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["adminApi"].getOverview().then({
                "AdminDashboard.useEffect": (data)=>{
                    if (!mounted) return;
                    setOverview(data);
                    setLastRefresh(new Date());
                }
            }["AdminDashboard.useEffect"]).catch({
                "AdminDashboard.useEffect": (reason)=>{
                    if (!mounted) return;
                    const message = reason instanceof __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$lib$2f$api$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["AdminApiError"] && reason.status === 401 ? "Yönetici oturumu bulunamadı. MFA ile tekrar giriş yapın." : "API'ye ulaşılamadı. Operasyon verileri canlı bağlantı kurulunca görünecek.";
                    setError(message);
                }
            }["AdminDashboard.useEffect"]).finally({
                "AdminDashboard.useEffect": ()=>mounted && setLoading(false)
            }["AdminDashboard.useEffect"]);
            return ({
                "AdminDashboard.useEffect": ()=>{
                    mounted = false;
                }
            })["AdminDashboard.useEffect"];
        }
    }["AdminDashboard.useEffect"], []);
    const meshSummary = (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useMemo"])({
        "AdminDashboard.useMemo[meshSummary]": ()=>`${overview.mesh.healthyNodes}/${overview.mesh.totalNodes}`
    }["AdminDashboard.useMemo[meshSummary]"], [
        overview.mesh
    ]);
    const updatedLabel = lastRefresh ? formatTime(lastRefresh.toISOString()) : "Bağlantı bekleniyor";
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        className: "admin-shell",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("aside", {
                className: "sidebar",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "brand",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                className: "brand-mark",
                                children: "a"
                            }, void 0, false, {
                                fileName: "[project]/apps/admin/app/page.tsx",
                                lineNumber: 116,
                                columnNumber: 32
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                        children: "alevi"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 116,
                                        columnNumber: 74
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        children: "operasyon merkezi"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 116,
                                        columnNumber: 96
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/apps/admin/app/page.tsx",
                                lineNumber: 116,
                                columnNumber: 69
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/apps/admin/app/page.tsx",
                        lineNumber: 116,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "workspace-label",
                        children: "YÖNETİM"
                    }, void 0, false, {
                        fileName: "[project]/apps/admin/app/page.tsx",
                        lineNumber: 117,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("nav", {
                        "aria-label": "Yönetim bölümleri",
                        children: navItems.map((item)=>{
                            const count = item.count === "users" ? overview.users.pendingVerification : item.count === "reports" ? overview.reports.open : item.count === "content" ? overview.content.pendingReview : item.count === "mesh" ? overview.mesh.totalNodes - overview.mesh.healthyNodes : 0;
                            return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("a", {
                                className: `nav-item ${item.active ? "active" : ""}`,
                                href: `#${item.label.toLocaleLowerCase("tr-TR").replace(/\s+/g, "-")}`,
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(Icon, {
                                        name: item.icon
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 121,
                                        columnNumber: 166
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        children: item.label
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 121,
                                        columnNumber: 191
                                    }, this),
                                    item.count && count > 0 ? /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("b", {
                                        children: formatNumber(count)
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 121,
                                        columnNumber: 243
                                    }, this) : null
                                ]
                            }, item.label, true, {
                                fileName: "[project]/apps/admin/app/page.tsx",
                                lineNumber: 121,
                                columnNumber: 20
                            }, this);
                        })
                    }, void 0, false, {
                        fileName: "[project]/apps/admin/app/page.tsx",
                        lineNumber: 118,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "sidebar-bottom",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("a", {
                                className: "nav-item",
                                href: "#ayarlar",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(Icon, {
                                        name: "settings"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 124,
                                        columnNumber: 81
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        children: "Ayarlar"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 124,
                                        columnNumber: 105
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/apps/admin/app/page.tsx",
                                lineNumber: 124,
                                columnNumber: 41
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "admin-identity",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        className: "avatar",
                                        children: "AY"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 124,
                                        columnNumber: 161
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                children: "Ayşe Y."
                                            }, void 0, false, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 124,
                                                columnNumber: 200
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("small", {
                                                children: "Baş yönetici"
                                            }, void 0, false, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 124,
                                                columnNumber: 224
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 124,
                                        columnNumber: 195
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        className: "identity-dots",
                                        children: "•••"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 124,
                                        columnNumber: 257
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/apps/admin/app/page.tsx",
                                lineNumber: 124,
                                columnNumber: 129
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/apps/admin/app/page.tsx",
                        lineNumber: 124,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 115,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("main", {
                className: "main-content",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("header", {
                        className: "topbar",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "breadcrumbs",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        children: "Yönetim"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 128,
                                        columnNumber: 65
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("i", {
                                        children: "/"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 128,
                                        columnNumber: 85
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                        children: "Genel bakış"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 128,
                                        columnNumber: 93
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/apps/admin/app/page.tsx",
                                lineNumber: 128,
                                columnNumber: 36
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "topbar-actions",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        className: "secure-label",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(Icon, {
                                                name: "shield"
                                            }, void 0, false, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 128,
                                                columnNumber: 190
                                            }, this),
                                            " Güvenli oturum"
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 128,
                                        columnNumber: 159
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        className: "icon-button",
                                        "aria-label": "Arama",
                                        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(Icon, {
                                            name: "search"
                                        }, void 0, false, {
                                            fileName: "[project]/apps/admin/app/page.tsx",
                                            lineNumber: 128,
                                            columnNumber: 285
                                        }, this)
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 128,
                                        columnNumber: 234
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        className: "notification-button",
                                        "aria-label": "Bildirimler",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                children: "3"
                                            }, void 0, false, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 128,
                                                columnNumber: 381
                                            }, this),
                                            "●"
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 128,
                                        columnNumber: 316
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        className: "top-avatar",
                                        children: "AY"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 128,
                                        columnNumber: 405
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/apps/admin/app/page.tsx",
                                lineNumber: 128,
                                columnNumber: 127
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/apps/admin/app/page.tsx",
                        lineNumber: 128,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "content-wrap",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("section", {
                                className: "page-intro",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "eyebrow",
                                                children: "21 EYLÜL 2026 · PAZARTESİ"
                                            }, void 0, false, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 130,
                                                columnNumber: 48
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h1", {
                                                children: "Günaydın, Ayşe"
                                            }, void 0, false, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 130,
                                                columnNumber: 100
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                className: "intro-copy",
                                                children: "Topluluğunuzun bugünkü operasyon görünümü."
                                            }, void 0, false, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 130,
                                                columnNumber: 123
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 130,
                                        columnNumber: 43
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "intro-status",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "live-dot"
                                            }, void 0, false, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 130,
                                                columnNumber: 231
                                            }, this),
                                            " Canlı izleme açık",
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "intro-divider"
                                            }, void 0, false, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 130,
                                                columnNumber: 278
                                            }, this),
                                            " ",
                                            updatedLabel
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 130,
                                        columnNumber: 201
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/apps/admin/app/page.tsx",
                                lineNumber: 130,
                                columnNumber: 11
                            }, this),
                            error && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "api-alert",
                                role: "status",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                        children: "Canlı veri bekleniyor"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 131,
                                        columnNumber: 62
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        children: error
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 131,
                                        columnNumber: 100
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                        onClick: ()=>window.location.reload(),
                                        children: "Yenile"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 131,
                                        columnNumber: 120
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/apps/admin/app/page.tsx",
                                lineNumber: 131,
                                columnNumber: 21
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("section", {
                                className: "metric-grid",
                                "aria-label": "Özet metrikler",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(MetricCard, {
                                        title: "Toplam kullanıcı",
                                        value: loading ? "—" : formatNumber(overview.users.total),
                                        caption: "kayıtlı topluluk üyesi",
                                        icon: "users",
                                        tone: "wine",
                                        footer: `+${formatNumber(overview.users.newThisWeek)} bu hafta`
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 134,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(MetricCard, {
                                        title: "Açık şikâyetler",
                                        value: loading ? "—" : formatNumber(overview.reports.open),
                                        caption: `${formatNumber(overview.reports.urgent)} yüksek öncelikli`,
                                        icon: "flag",
                                        tone: "amber",
                                        footer: `${formatNumber(overview.reports.resolvedToday)} bugün çözüldü`
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 135,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(MetricCard, {
                                        title: "İçerik inceleme",
                                        value: loading ? "—" : formatNumber(overview.content.pendingReview),
                                        caption: "işlem bekleyen içerik",
                                        icon: "layers",
                                        tone: "blue",
                                        footer: `${formatNumber(overview.content.appeals)} itiraz bekliyor`
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 136,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(MetricCard, {
                                        title: "Mesh sağlığı",
                                        value: loading ? "—" : meshSummary,
                                        caption: "node erişilebilir",
                                        icon: "pulse",
                                        tone: "green",
                                        footer: `${formatNumber(overview.mesh.averageLatencyMs)} ms ort. gecikme`
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 137,
                                        columnNumber: 13
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/apps/admin/app/page.tsx",
                                lineNumber: 133,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("section", {
                                className: "main-grid",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("article", {
                                        className: "panel activity-panel",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "panel-heading",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                                className: "eyebrow",
                                                                children: "OPERASYON AKIŞI"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 141,
                                                                columnNumber: 91
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                                                                children: "Son aktiviteler"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 141,
                                                                columnNumber: 133
                                                            }, this)
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 141,
                                                        columnNumber: 86
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                                        className: "text-button",
                                                        children: [
                                                            "Tümünü gör ",
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                children: "→"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 141,
                                                                columnNumber: 206
                                                            }, this)
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 141,
                                                        columnNumber: 163
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 141,
                                                columnNumber: 55
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "activity-list",
                                                children: overview.activity.length === 0 ? /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                    className: "empty-state",
                                                    children: [
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                            className: "empty-symbol",
                                                            children: "◌"
                                                        }, void 0, false, {
                                                            fileName: "[project]/apps/admin/app/page.tsx",
                                                            lineNumber: 141,
                                                            columnNumber: 329
                                                        }, this),
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                            children: loading ? "Aktiviteler yükleniyor" : "Görüntülenecek yeni aktivite yok"
                                                        }, void 0, false, {
                                                            fileName: "[project]/apps/admin/app/page.tsx",
                                                            lineNumber: 141,
                                                            columnNumber: 368
                                                        }, this),
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                            children: "Canlı API bağlantısı kurulduğunda olaylar burada listelenir."
                                                        }, void 0, false, {
                                                            fileName: "[project]/apps/admin/app/page.tsx",
                                                            lineNumber: 141,
                                                            columnNumber: 458
                                                        }, this)
                                                    ]
                                                }, void 0, true, {
                                                    fileName: "[project]/apps/admin/app/page.tsx",
                                                    lineNumber: 141,
                                                    columnNumber: 300
                                                }, this) : overview.activity.map((event)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: "activity-row",
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                className: `activity-icon ${event.kind}`,
                                                                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(Icon, {
                                                                    name: event.kind === "report" ? "flag" : event.kind === "mesh" ? "pulse" : event.kind === "user" ? "users" : "layers"
                                                                }, void 0, false, {
                                                                    fileName: "[project]/apps/admin/app/page.tsx",
                                                                    lineNumber: 141,
                                                                    columnNumber: 666
                                                                }, this)
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 141,
                                                                columnNumber: 618
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                                children: [
                                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                                        children: event.title
                                                                    }, void 0, false, {
                                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                                        lineNumber: 141,
                                                                        columnNumber: 805
                                                                    }, this),
                                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                                        children: event.detail
                                                                    }, void 0, false, {
                                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                                        lineNumber: 141,
                                                                        columnNumber: 835
                                                                    }, this)
                                                                ]
                                                            }, void 0, true, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 141,
                                                                columnNumber: 800
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("time", {
                                                                children: relativeTime(event.occurredAt)
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 141,
                                                                columnNumber: 862
                                                            }, this)
                                                        ]
                                                    }, event.id, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 141,
                                                        columnNumber: 573
                                                    }, this))
                                            }, void 0, false, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 141,
                                                columnNumber: 235
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 141,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("article", {
                                        className: "panel health-panel",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "panel-heading",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                                className: "eyebrow",
                                                                children: "ALTYAPI"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 142,
                                                                columnNumber: 89
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                                                                children: "Mesh sağlığı"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 142,
                                                                columnNumber: 123
                                                            }, this)
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 142,
                                                        columnNumber: 84
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(HealthPill, {
                                                        state: overview.mesh.state
                                                    }, void 0, false, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 142,
                                                        columnNumber: 150
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 142,
                                                columnNumber: 53
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "health-visual",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: `health-ring ${overview.mesh.state}`,
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                                children: [
                                                                    overview.mesh.totalNodes ? Math.round(overview.mesh.healthyNodes / overview.mesh.totalNodes * 100) : 0,
                                                                    "%"
                                                                ]
                                                            }, void 0, true, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 142,
                                                                columnNumber: 283
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                children: "erişilebilir"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 142,
                                                                columnNumber: 407
                                                            }, this)
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 142,
                                                        columnNumber: 229
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: "health-details",
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                                children: [
                                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                        children: "Aktif node"
                                                                    }, void 0, false, {
                                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                                        lineNumber: 142,
                                                                        columnNumber: 475
                                                                    }, this),
                                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                                        children: meshSummary
                                                                    }, void 0, false, {
                                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                                        lineNumber: 142,
                                                                        columnNumber: 498
                                                                    }, this)
                                                                ]
                                                            }, void 0, true, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 142,
                                                                columnNumber: 470
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                                children: [
                                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                        children: "Son senkronizasyon"
                                                                    }, void 0, false, {
                                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                                        lineNumber: 142,
                                                                        columnNumber: 539
                                                                    }, this),
                                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                                        children: formatTime(overview.mesh.lastSyncAt)
                                                                    }, void 0, false, {
                                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                                        lineNumber: 142,
                                                                        columnNumber: 570
                                                                    }, this)
                                                                ]
                                                            }, void 0, true, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 142,
                                                                columnNumber: 534
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                                children: [
                                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                        children: "Ortalama gecikme"
                                                                    }, void 0, false, {
                                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                                        lineNumber: 142,
                                                                        columnNumber: 636
                                                                    }, this),
                                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                                        children: [
                                                                            formatNumber(overview.mesh.averageLatencyMs),
                                                                            " ms"
                                                                        ]
                                                                    }, void 0, true, {
                                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                                        lineNumber: 142,
                                                                        columnNumber: 665
                                                                    }, this)
                                                                ]
                                                            }, void 0, true, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 142,
                                                                columnNumber: 631
                                                            }, this)
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 142,
                                                        columnNumber: 438
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 142,
                                                columnNumber: 198
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "node-bars",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: "node-bar-label",
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                children: "Node kullanılabilirliği"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 142,
                                                                columnNumber: 808
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                                children: [
                                                                    overview.mesh.healthyNodes,
                                                                    " / ",
                                                                    overview.mesh.totalNodes
                                                                ]
                                                            }, void 0, true, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 142,
                                                                columnNumber: 844
                                                            }, this)
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 142,
                                                        columnNumber: 776
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: "progress-track",
                                                        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                            style: {
                                                                width: `${overview.mesh.totalNodes ? overview.mesh.healthyNodes / overview.mesh.totalNodes * 100 : 0}%`
                                                            }
                                                        }, void 0, false, {
                                                            fileName: "[project]/apps/admin/app/page.tsx",
                                                            lineNumber: 142,
                                                            columnNumber: 956
                                                        }, this)
                                                    }, void 0, false, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 142,
                                                        columnNumber: 924
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 142,
                                                columnNumber: 749
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                                className: "outline-button",
                                                children: [
                                                    "Mesh ayrıntılarını aç ",
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                        children: "→"
                                                    }, void 0, false, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 142,
                                                        columnNumber: 1151
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 142,
                                                columnNumber: 1094
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 142,
                                        columnNumber: 13
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/apps/admin/app/page.tsx",
                                lineNumber: 140,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("section", {
                                className: "bottom-grid",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("article", {
                                        className: "panel quick-panel",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "panel-heading",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                                className: "eyebrow",
                                                                children: "HIZLI GÖRÜNÜM"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 119
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                                                                children: "Bugünün özeti"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 159
                                                            }, this)
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 145,
                                                        columnNumber: 114
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                        className: "date-badge",
                                                        children: "21 Eyl"
                                                    }, void 0, false, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 145,
                                                        columnNumber: 187
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 145,
                                                columnNumber: 83
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "quick-list",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                className: "quick-icon green",
                                                                children: "✓"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 268
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                children: "Çözülen şikâyetler"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 311
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                                children: formatNumber(overview.reports.resolvedToday)
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 342
                                                            }, this)
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 145,
                                                        columnNumber: 263
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                className: "quick-icon blue",
                                                                children: "↗"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 416
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                children: "Aktif kullanıcı (24 sa)"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 458
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                                children: formatNumber(overview.users.active24h)
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 494
                                                            }, this)
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 145,
                                                        columnNumber: 411
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                className: "quick-icon amber",
                                                                children: "!"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 562
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                children: "Kaldırılan içerik"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 605
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                                children: formatNumber(overview.content.removedToday)
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 635
                                                            }, this)
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 145,
                                                        columnNumber: 557
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                className: "quick-icon wine",
                                                                children: "◷"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 708
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                children: "Ort. yanıt süresi"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 750
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("strong", {
                                                                children: [
                                                                    formatNumber(overview.reports.medianResponseMinutes),
                                                                    " dk"
                                                                ]
                                                            }, void 0, true, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 780
                                                            }, this)
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 145,
                                                        columnNumber: 703
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 145,
                                                columnNumber: 235
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 145,
                                        columnNumber: 44
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("article", {
                                        className: "panel security-panel",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "panel-heading",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                                className: "eyebrow",
                                                                children: "GÜVENLİK MERKEZİ"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 954
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                                                                children: "Kontrol noktaları"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 997
                                                            }, this)
                                                        ]
                                                    }, void 0, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 145,
                                                        columnNumber: 949
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                        className: "security-score",
                                                        children: "4/5"
                                                    }, void 0, false, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 145,
                                                        columnNumber: 1029
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 145,
                                                columnNumber: 918
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "security-list",
                                                children: __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$lib$2f$security$2e$ts__$5b$app$2d$client$5d$__$28$ecmascript$29$__["adminSecurityNotes"].slice(0, 4).map((note)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: "security-row",
                                                        children: [
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                className: `security-status ${note.tone}`
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 1202
                                                            }, this),
                                                            " ",
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                                children: note.title
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 1254
                                                            }, this),
                                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("small", {
                                                                children: note.tone === "good" ? "Etkin" : "İncele"
                                                            }, void 0, false, {
                                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                                lineNumber: 145,
                                                                columnNumber: 1279
                                                            }, this)
                                                        ]
                                                    }, note.title, true, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 145,
                                                        columnNumber: 1155
                                                    }, this))
                                            }, void 0, false, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 145,
                                                columnNumber: 1078
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("a", {
                                                className: "security-link",
                                                href: "#security",
                                                children: [
                                                    "Güvenlik kontrollerini görüntüle ",
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                        children: "→"
                                                    }, void 0, false, {
                                                        fileName: "[project]/apps/admin/app/page.tsx",
                                                        lineNumber: 145,
                                                        columnNumber: 1430
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/apps/admin/app/page.tsx",
                                                lineNumber: 145,
                                                columnNumber: 1351
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 145,
                                        columnNumber: 876
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/apps/admin/app/page.tsx",
                                lineNumber: 145,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("footer", {
                                className: "page-footer",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        children: "Alevi Operasyon Merkezi · v0.1 iskelet"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 146,
                                        columnNumber: 43
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                        children: "Veriler amaç sınırlı ve maskeli gösterilir · KVKK"
                                    }, void 0, false, {
                                        fileName: "[project]/apps/admin/app/page.tsx",
                                        lineNumber: 146,
                                        columnNumber: 94
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/apps/admin/app/page.tsx",
                                lineNumber: 146,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/apps/admin/app/page.tsx",
                        lineNumber: 129,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/apps/admin/app/page.tsx",
                lineNumber: 127,
                columnNumber: 7
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/apps/admin/app/page.tsx",
        lineNumber: 114,
        columnNumber: 5
    }, this);
}
_s(AdminDashboard, "gmwZ94wmzUlGENE+szElnwtr8I8=");
_c3 = AdminDashboard;
var _c, _c1, _c2, _c3;
__turbopack_context__.k.register(_c, "Icon");
__turbopack_context__.k.register(_c1, "HealthPill");
__turbopack_context__.k.register(_c2, "MetricCard");
__turbopack_context__.k.register(_c3, "AdminDashboard");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/apps/admin/lib/api.ts [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "AdminApiClient",
    ()=>AdminApiClient,
    "AdminApiError",
    ()=>AdminApiError,
    "adminApi",
    ()=>adminApi
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$build$2f$polyfills$2f$process$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = /*#__PURE__*/ __turbopack_context__.i("[project]/apps/admin/node_modules/next/dist/build/polyfills/process.js [app-client] (ecmascript)");
class AdminApiError extends Error {
    status;
    requestId;
    constructor(message, status, requestId){
        super(message);
        this.name = "AdminApiError";
        this.status = status;
        this.requestId = requestId;
    }
}
function readCookie(name) {
    if (typeof document === "undefined") return undefined;
    const prefix = `${encodeURIComponent(name)}=`;
    const cookie = document.cookie.split(";").map((item)=>item.trim()).find((item)=>item.startsWith(prefix));
    return cookie ? decodeURIComponent(cookie.slice(prefix.length)) : undefined;
}
function getApiBaseUrl() {
    const configured = __TURBOPACK__imported__module__$5b$project$5d2f$apps$2f$admin$2f$node_modules$2f$next$2f$dist$2f$build$2f$polyfills$2f$process$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["default"].env.NEXT_PUBLIC_ADMIN_API_URL?.trim();
    return (configured || "/v1/admin").replace(/\/$/, "");
}
class AdminApiClient {
    baseUrl;
    constructor(baseUrl = getApiBaseUrl()){
        this.baseUrl = baseUrl;
    }
    async request(path, init = {}) {
        const headers = new Headers(init.headers);
        headers.set("Accept", "application/json");
        if (init.body && !headers.has("Content-Type")) {
            headers.set("Content-Type", "application/json");
        }
        // Mutating API calls can use a double-submit CSRF cookie. GET requests do
        // not need it, but adding the header when present keeps the client generic.
        if (init.method && ![
            "GET",
            "HEAD",
            "OPTIONS"
        ].includes(init.method.toUpperCase())) {
            const csrf = readCookie("csrf_token") ?? readCookie("XSRF-TOKEN");
            if (csrf) headers.set("X-CSRF-Token", csrf);
        }
        const response = await fetch(`${this.baseUrl}${path}`, {
            ...init,
            headers,
            credentials: "include",
            cache: "no-store"
        });
        if (!response.ok) {
            let message = `Admin API isteği başarısız (${response.status})`;
            try {
                const body = await response.json();
                if (body.message) message = body.message;
            } catch  {
            // Error body is optional; keep the status-based message.
            }
            throw new AdminApiError(message, response.status, response.headers.get("x-request-id") ?? undefined);
        }
        if (response.status === 204) return undefined;
        const rawBody = await response.text();
        if (!rawBody.trim()) return undefined;
        try {
            return JSON.parse(rawBody);
        } catch  {
            throw new AdminApiError("Admin API geçersiz JSON döndürdü", 502, response.headers.get("x-request-id") ?? undefined);
        }
    }
    getOverview() {
        return this.request("/overview");
    }
    getMeshHealth() {
        return this.request("/mesh/health");
    }
    async suspendUser(userId, reason) {
        await this.request(`/users/${encodeURIComponent(userId)}/suspend`, {
            method: "POST",
            body: JSON.stringify({
                reason
            })
        });
    }
    async resolveReport(reportId, action) {
        await this.request(`/reports/${encodeURIComponent(reportId)}/resolve`, {
            method: "POST",
            body: JSON.stringify({
                action
            })
        });
    }
}
const adminApi = new AdminApiClient();
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
"[project]/apps/admin/lib/security.ts [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "adminSecurityNotes",
    ()=>adminSecurityNotes
]);
const adminSecurityNotes = [
    {
        title: "MFA ve kısa oturum",
        description: "Yönetici girişi MFA zorunlu, HttpOnly/Secure oturum çerezi ve kısa idle timeout ile korunur.",
        tone: "good"
    },
    {
        title: "Sunucu tarafı RBAC",
        description: "Rol ve amaç kontrolü her istekte API tarafından uygulanır; butonu gizlemek yetkilendirme değildir.",
        tone: "good"
    },
    {
        title: "Hassas veri maskesi",
        description: "Dini/kültürel alanlar ve iletişim bilgileri varsayılan olarak maskelidir; gereksiz veri çekilmez.",
        tone: "warning"
    },
    {
        title: "Değiştirilemez denetim izi",
        description: "Suspend, silme, dışa aktarma ve erişim olayları kullanıcı, amaç ve zaman bilgisiyle audit log'a yazılır.",
        tone: "good"
    },
    {
        title: "Token saklama yasağı",
        description: "Access token localStorage/sessionStorage'a yazılmaz. İstemci yalnızca güvenli oturum çerezi ve CSRF akışı kullanır.",
        tone: "critical"
    }
];
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
]);

//# sourceMappingURL=apps_admin_1m7yk4u._.js.map