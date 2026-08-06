"""
ARR Dashboard 2.0 — Replacing Power BI with Real-Time Snowflake Analytics
Deployed on: Snowpark Container Services (SPCS)
Source: ARR_WAREHOUSE.ARR_ANALYTICS
"""

import os
import streamlit as st
import pandas as pd
import plotly.graph_objects as go
import snowflake.connector

# =============================================================
# PAGE CONFIG
# =============================================================
st.set_page_config(
    page_title="ARR Dashboard 2.0",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded",
)

# =============================================================
# ENTERPRISE THEME
# =============================================================
COLORS = {
    "blue": "#2E5FA1",
    "orange": "#E87722",
    "dark_blue": "#1B3A5C",
    "green": "#4CAF50",
    "red": "#D32F2F",
    "grey": "#546E7A",
    "dark_green": "#1B5E20",
    "black": "#1A1A1A",
    "white": "#FFFFFF",
}

st.markdown("""
<style>
    .main { background-color: #FFFFFF; }
    .stApp { background-color: #FFFFFF; }
    section[data-testid="stSidebar"] { background-color: #F8F9FA; }
    .dashboard-title {
        font-size: 22px; font-weight: 700; color: #1A1A1A;
        font-family: 'Segoe UI', sans-serif; padding: 4px 0 2px 0; margin: 0;
    }
    .dashboard-subtitle {
        font-size: 12px; color: #666666;
        font-family: 'Segoe UI', sans-serif; margin-top: 0; margin-bottom: 16px;
    }
    .slicer-header {
        background-color: #1A1A1A; color: #FFFFFF;
        padding: 6px 12px; font-size: 11px; font-weight: 600;
        font-family: 'Segoe UI', sans-serif; border-radius: 3px; margin: 10px 0 4px 0;
    }
    .visual-title {
        color: #1B5E20; font-size: 14px; font-weight: 600;
        font-family: 'Segoe UI', sans-serif; margin-bottom: 0; padding-left: 2px;
    }
    .kpi-card {
        background: #FFFFFF; border: 1px solid #E0E0E0; border-radius: 4px;
        padding: 14px; text-align: center;
    }
    .kpi-label {
        color: #1B5E20; font-size: 11px; font-weight: 600; font-family: 'Segoe UI', sans-serif;
    }
    .kpi-value {
        color: #1A1A1A; font-size: 20px; font-weight: 700;
        font-family: 'Segoe UI', sans-serif; margin-top: 4px;
    }
    .stTabs [data-baseweb="tab-list"] { gap: 0px; border-bottom: 2px solid #E0E0E0; }
    .stTabs [data-baseweb="tab"] { padding: 8px 24px; font-size: 13px; font-weight: 500; color: #666; }
    .stTabs [aria-selected="true"] { color: #1B5E20 !important; border-bottom: 2px solid #1B5E20 !important; font-weight: 600; }
    #MainMenu { visibility: hidden; }
    footer { visibility: hidden; }
    .stDeployButton { display: none; }
</style>
""", unsafe_allow_html=True)


# =============================================================
# SNOWFLAKE CONNECTION (SPCS - token-based auth)
# =============================================================
@st.cache_resource
def get_connection():
    """Connect to Snowflake using SPCS OAuth token (injected by container runtime)."""
    token_path = "/snowflake/session/token"
    if os.path.exists(token_path):
        with open(token_path, "r") as f:
            token = f.read().strip()
        conn = snowflake.connector.connect(
            host=os.environ.get("SNOWFLAKE_HOST", ""),
            account=os.environ.get("SNOWFLAKE_ACCOUNT", ""),
            token=token,
            authenticator="oauth",
            database="ARR_WAREHOUSE",
            schema="ARR_ANALYTICS",
            warehouse=os.environ.get("SNOWFLAKE_WAREHOUSE", "AI_WH"),
        )
    else:
        # Fallback for local Docker testing
        conn = snowflake.connector.connect(
            connection_name="SPCS",
            database="ARR_WAREHOUSE",
            schema="ARR_ANALYTICS",
            warehouse="AI_WH",
            role="SYSADMIN",
        )
    return conn


@st.cache_data(ttl=300)
def run_query(query):
    """Execute a query and return a pandas DataFrame."""
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(query)
        columns = [desc[0] for desc in cur.description]
        data = cur.fetchall()
        return pd.DataFrame(data, columns=columns)
    finally:
        cur.close()


# =============================================================
# LOAD DATA FROM SNOWFLAKE
# =============================================================
@st.cache_data(ttl=300)
def load_all_data():

    metrics = run_query("SELECT * FROM V_ARR_WATERFALL ORDER BY METRIC_MONTH")
    movements = run_query("SELECT * FROM V_ARR_MOVEMENT_DETAIL ORDER BY MOVEMENT_MONTH")
    customers = run_query("SELECT * FROM V_ARR_BY_CUSTOMER")
    retention = run_query("SELECT * FROM V_RETENTION_RATES ORDER BY METRIC_MONTH")
    products = run_query("SELECT * FROM V_ARR_BY_PRODUCT ORDER BY SNAPSHOT_DATE, TOTAL_ARR DESC")
    subscriptions = run_query("SELECT * FROM V_SUBSCRIPTION_HEALTH ORDER BY DAYS_TO_RENEWAL")
    quarterly = run_query("SELECT * FROM FACT_ARR_FINAL_METRICS ORDER BY PERIOD_START_DATE")
    dim_customers = run_query("SELECT DISTINCT SEGMENT, REGION, ACCOUNT_OWNER FROM DIM_CUSTOMER WHERE CUSTOMER_STATUS = 'Active'")
    dim_products = run_query("SELECT DISTINCT PRODUCT_FAMILY, PRODUCT_TIER FROM DIM_PRODUCT WHERE IS_ACTIVE = TRUE")
    dim_classifications = run_query("SELECT * FROM DIM_ARR_CLASSIFICATION ORDER BY SORT_ORDER")

    return {
        "metrics": metrics,
        "movements": movements,
        "customers": customers,
        "retention": retention,
        "products": products,
        "subscriptions": subscriptions,
        "quarterly": quarterly,
        "dim_customers": dim_customers,
        "dim_products": dim_products,
        "dim_classifications": dim_classifications,
    }


# Load data
try:
    data = load_all_data()
    connection_ok = True
except Exception as e:
    connection_ok = False
    error_msg = str(e)


# =============================================================
# SIDEBAR SLICERS
# =============================================================
with st.sidebar:
    st.markdown('<p style="font-size:16px;font-weight:700;color:#1A1A1A;">Filters</p>', unsafe_allow_html=True)

    if connection_ok:
        st.markdown('<div class="slicer-header">Year</div>', unsafe_allow_html=True)
        years = sorted(data["metrics"]["YEAR_NUM"].unique())
        sel_year = st.multiselect("Year", years, default=years, key="f_year", label_visibility="collapsed")

        st.markdown('<div class="slicer-header">Quarter</div>', unsafe_allow_html=True)
        quarters = sorted(data["metrics"]["QUARTER_NAME"].unique())
        sel_quarter = st.multiselect("Quarter", quarters, default=quarters, key="f_quarter", label_visibility="collapsed")

        st.markdown('<div class="slicer-header">Region</div>', unsafe_allow_html=True)
        regions = sorted(data["dim_customers"]["REGION"].unique())
        sel_region = st.multiselect("Region", regions, default=regions, key="f_region", label_visibility="collapsed")

        st.markdown('<div class="slicer-header">Segment</div>', unsafe_allow_html=True)
        segments = sorted(data["dim_customers"]["SEGMENT"].unique())
        sel_segment = st.multiselect("Segment", segments, default=segments, key="f_segment", label_visibility="collapsed")

        st.markdown('<div class="slicer-header">Movement Type</div>', unsafe_allow_html=True)
        move_types = data["dim_classifications"]["CLASSIFICATION_NAME"].tolist()
        sel_move_type = st.multiselect("Movement Type", move_types, default=move_types, key="f_move", label_visibility="collapsed")

        st.markdown('<div class="slicer-header">Account Owner</div>', unsafe_allow_html=True)
        owners = sorted(data["dim_customers"]["ACCOUNT_OWNER"].unique())
        sel_owner = st.multiselect("Account Owner", owners, default=owners, key="f_owner", label_visibility="collapsed")

    st.markdown("---")
    st.markdown('<p style="font-size:10px;color:#999;text-align:center;">ARR Dashboard v2.0<br>SPCS Container</p>', unsafe_allow_html=True)


# =============================================================
# HEADER
# =============================================================
st.markdown('<p class="dashboard-title">ARR Dashboard 2.0 — Replacing Power BI with Real-Time Snowflake Analytics</p>', unsafe_allow_html=True)
st.markdown('<p class="dashboard-subtitle">Live from Snowflake | ARR_WAREHOUSE.ARR_ANALYTICS | SPCS Container</p>', unsafe_allow_html=True)

if not connection_ok:
    st.error(f"Failed to connect to Snowflake: {error_msg}")
    st.stop()


# =============================================================
# APPLY FILTERS
# =============================================================
metrics = data["metrics"][
    (data["metrics"]["YEAR_NUM"].isin(sel_year)) &
    (data["metrics"]["QUARTER_NAME"].isin(sel_quarter))
].copy()

movements = data["movements"][
    (data["movements"]["YEAR_NUM"].isin(sel_year)) &
    (data["movements"]["QUARTER_NAME"].isin(sel_quarter)) &
    (data["movements"]["REGION"].isin(sel_region)) &
    (data["movements"]["SEGMENT"].isin(sel_segment)) &
    (data["movements"]["CLASSIFICATION_NAME"].isin(sel_move_type))
].copy()

customers = data["customers"][
    (data["customers"]["REGION"].isin(sel_region)) &
    (data["customers"]["SEGMENT"].isin(sel_segment))
].copy()

subscriptions = data["subscriptions"][
    (data["subscriptions"]["REGION"].isin(sel_region)) &
    (data["subscriptions"]["SEGMENT"].isin(sel_segment))
].copy()


# =============================================================
# TABS
# =============================================================
tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
    "📈 ARR Summary & Trends",
    "📊 ARR Breakdown",
    "👤 Sales Rep Performance",
    "🔄 Retention & Churn",
    "🤖 AI Assistant",
    "🗄️ Data Catalog",
])


# =============================================================
# TAB 1: ARR SUMMARY & TRENDS
# =============================================================
with tab1:
    if metrics.empty:
        st.warning("No data for selected filters.")
    else:
        latest = metrics.iloc[-1]

        c1, c2, c3, c4, c5 = st.columns(5)
        with c1:
            st.markdown(f'<div class="kpi-card"><div class="kpi-label">Last Dataset Refresh</div><div class="kpi-value">04-10-2026</div></div>', unsafe_allow_html=True)
        with c2:
            st.markdown(f'<div class="kpi-card"><div class="kpi-label">Ending ARR</div><div class="kpi-value">${latest["ENDING_ARR"]:,.0f}</div></div>', unsafe_allow_html=True)
        with c3:
            net = latest["NET_NEW_ARR"]
            color = "#4CAF50" if net >= 0 else "#D32F2F"
            st.markdown(f'<div class="kpi-card"><div class="kpi-label">Net New ARR (Latest)</div><div class="kpi-value" style="color:{color}">${net:,.0f}</div></div>', unsafe_allow_html=True)
        with c4:
            grr = latest["GROSS_RETENTION_RATE"]
            st.markdown(f'<div class="kpi-card"><div class="kpi-label">Gross Retention Rate</div><div class="kpi-value">{grr:.1%}</div></div>', unsafe_allow_html=True)
        with c5:
            nrr = latest["NET_RETENTION_RATE"]
            st.markdown(f'<div class="kpi-card"><div class="kpi-label">Net Retention Rate</div><div class="kpi-value">{nrr:.1%}</div></div>', unsafe_allow_html=True)

        st.markdown("<br>", unsafe_allow_html=True)

        col1, col2 = st.columns(2)
        with col1:
            st.markdown('<p class="visual-title">Ending ARR</p>', unsafe_allow_html=True)
            fig = go.Figure()
            fig.add_trace(go.Scatter(x=metrics["YEAR_MONTH"], y=metrics["ENDING_ARR"],
                mode="lines+markers", line=dict(color=COLORS["blue"], width=3), marker=dict(size=5),
                hovertemplate="<b>%{x}</b><br>$%{y:,.0f}<extra></extra>"))
            fig.update_layout(height=280, margin=dict(l=50, r=20, t=10, b=50),
                plot_bgcolor="#FFF", paper_bgcolor="#FFF",
                xaxis=dict(tickangle=-45, tickfont=dict(size=9)),
                yaxis=dict(tickformat="$,.0s", gridcolor="#E8E8E8"), showlegend=False)
            st.plotly_chart(fig, use_container_width=True)

        with col2:
            st.markdown('<p class="visual-title">Retention Trends</p>', unsafe_allow_html=True)
            fig = go.Figure()
            fig.add_trace(go.Scatter(x=metrics["YEAR_MONTH"], y=metrics["GROSS_RETENTION_RATE"],
                mode="lines+markers", line=dict(color=COLORS["blue"], width=3), name="GRR"))
            fig.add_trace(go.Scatter(x=metrics["YEAR_MONTH"], y=metrics["NET_RETENTION_RATE"],
                mode="lines+markers", line=dict(color=COLORS["orange"], width=3), name="NRR"))
            fig.update_layout(height=280, margin=dict(l=50, r=20, t=10, b=50),
                plot_bgcolor="#FFF", paper_bgcolor="#FFF",
                xaxis=dict(tickangle=-45, tickfont=dict(size=9)),
                yaxis=dict(tickformat=".0%", gridcolor="#E8E8E8", range=[0.8, 1.15]),
                legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="left", x=0))
            st.plotly_chart(fig, use_container_width=True)

        col3, col4 = st.columns([3, 2])
        with col3:
            st.markdown('<p class="visual-title">ARR Types and Net Impact to Monthly ARR</p>', unsafe_allow_html=True)
            fig = go.Figure()
            fig.add_trace(go.Bar(x=metrics["YEAR_MONTH"], y=metrics["CHURN_ARR"], name="Churn", marker_color=COLORS["red"]))
            fig.add_trace(go.Bar(x=metrics["YEAR_MONTH"], y=metrics["EXPANSION_ARR"] + metrics["CONTRACTION_ARR"], name="Net Upsell/Downsell", marker_color=COLORS["green"]))
            fig.add_trace(go.Bar(x=metrics["YEAR_MONTH"], y=metrics["NEW_BUSINESS_ARR"], name="New Logo", marker_color=COLORS["orange"]))
            fig.add_trace(go.Bar(x=metrics["YEAR_MONTH"], y=metrics["FX_ADJUSTMENT_ARR"], name="FX Adjustment", marker_color=COLORS["grey"]))
            fig.add_trace(go.Scatter(x=metrics["YEAR_MONTH"], y=metrics["NET_NEW_ARR"],
                mode="lines+markers", line=dict(color=COLORS["dark_blue"], width=3), marker=dict(size=6), name="Net ARR"))
            fig.update_layout(barmode="relative", height=320, margin=dict(l=50, r=20, t=10, b=50),
                plot_bgcolor="#FFF", paper_bgcolor="#FFF",
                xaxis=dict(tickangle=-45, tickfont=dict(size=9)),
                yaxis=dict(tickformat="$,.0s", gridcolor="#E8E8E8"),
                legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="left", x=0, font=dict(size=9)))
            st.plotly_chart(fig, use_container_width=True)

        with col4:
            st.markdown('<p class="visual-title">Monthly ARR Waterfall</p>', unsafe_allow_html=True)
            waterfall_df = metrics[["YEAR_MONTH", "BEGINNING_ARR", "NEW_BUSINESS_ARR", "EXPANSION_ARR",
                "CONTRACTION_ARR", "CHURN_ARR", "RESURRECTION_ARR", "FX_ADJUSTMENT_ARR",
                "NET_NEW_ARR", "ENDING_ARR"]].copy()
            waterfall_display = waterfall_df.set_index("YEAR_MONTH")
            for col in waterfall_display.columns:
                waterfall_display[col] = waterfall_display[col].apply(lambda x: f"${x:,.0f}")
            st.dataframe(waterfall_display, use_container_width=True, height=300)


# =============================================================
# TAB 2: ARR BREAKDOWN
# =============================================================
with tab2:
    if movements.empty and customers.empty:
        st.warning("No data for selected filters.")
    else:
        col1, col2, col3 = st.columns(3)
        with col1:
            st.markdown('<p class="visual-title">ARR by Movement Type</p>', unsafe_allow_html=True)
            type_data = movements.groupby("CLASSIFICATION_NAME")["ARR_DELTA"].sum().reset_index()
            if not type_data.empty:
                type_colors = {"New Business": "#E87722", "Expansion": "#4CAF50", "Contraction": "#7B2D8B",
                    "Churn": "#D32F2F", "Resurrection": "#2E5FA1", "FX Adjustment": "#546E7A"}
                fig = go.Figure(data=[go.Pie(labels=type_data["CLASSIFICATION_NAME"], values=type_data["ARR_DELTA"].abs(),
                    hole=0.45, marker=dict(colors=[type_colors.get(t, "#999") for t in type_data["CLASSIFICATION_NAME"]]),
                    textinfo="label+percent", textfont=dict(size=10))])
                fig.update_layout(height=280, margin=dict(l=10, r=10, t=10, b=10), paper_bgcolor="#FFF", showlegend=False)
                st.plotly_chart(fig, use_container_width=True)

        with col2:
            st.markdown('<p class="visual-title">Current ARR by Region</p>', unsafe_allow_html=True)
            if not customers.empty:
                region_data = customers.groupby("REGION")["CURRENT_ARR"].sum().reset_index().sort_values("CURRENT_ARR", ascending=False)
                fig = go.Figure(go.Bar(x=region_data["CURRENT_ARR"], y=region_data["REGION"], orientation="h", marker_color=COLORS["blue"]))
                fig.update_layout(height=280, margin=dict(l=110, r=20, t=10, b=30),
                    plot_bgcolor="#FFF", paper_bgcolor="#FFF", xaxis=dict(tickformat="$,.0s", gridcolor="#E8E8E8"))
                st.plotly_chart(fig, use_container_width=True)

        with col3:
            st.markdown('<p class="visual-title">Current ARR by Segment</p>', unsafe_allow_html=True)
            if not customers.empty:
                seg_data = customers.groupby("SEGMENT")["CURRENT_ARR"].sum().reset_index().sort_values("CURRENT_ARR", ascending=False)
                fig = go.Figure(go.Bar(x=seg_data["CURRENT_ARR"], y=seg_data["SEGMENT"], orientation="h", marker_color=COLORS["dark_blue"]))
                fig.update_layout(height=280, margin=dict(l=110, r=20, t=10, b=30),
                    plot_bgcolor="#FFF", paper_bgcolor="#FFF", xaxis=dict(tickformat="$,.0s", gridcolor="#E8E8E8"))
                st.plotly_chart(fig, use_container_width=True)

        st.markdown('<p class="visual-title">Monthly ARR by Classification Group</p>', unsafe_allow_html=True)
        if not movements.empty:
            cat_monthly = movements.groupby(["YEAR_MONTH", "CLASSIFICATION_GROUP"])["ARR_DELTA"].sum().reset_index()
            cat_colors = {"Growth": "#4CAF50", "Contraction": "#D32F2F", "Adjustment": "#546E7A"}
            fig = go.Figure()
            for cat in ["Growth", "Contraction", "Adjustment"]:
                subset = cat_monthly[cat_monthly["CLASSIFICATION_GROUP"] == cat]
                if not subset.empty:
                    fig.add_trace(go.Bar(x=subset["YEAR_MONTH"], y=subset["ARR_DELTA"], name=cat, marker_color=cat_colors.get(cat, "#999")))
            fig.update_layout(barmode="relative", height=300, margin=dict(l=50, r=20, t=10, b=50),
                plot_bgcolor="#FFF", paper_bgcolor="#FFF", xaxis=dict(tickangle=-45, tickfont=dict(size=9)),
                yaxis=dict(tickformat="$,.0s", gridcolor="#E8E8E8"),
                legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="left", x=0))
            st.plotly_chart(fig, use_container_width=True)


# =============================================================
# TAB 3: SALES REP PERFORMANCE
# =============================================================
with tab3:
    if customers.empty:
        st.warning("No data for selected filters.")
    else:
        col1, col2 = st.columns(2)
        with col1:
            st.markdown('<p class="visual-title">Current ARR by Account Owner</p>', unsafe_allow_html=True)
            owner_data = customers.groupby("ACCOUNT_OWNER")["CURRENT_ARR"].sum().reset_index().sort_values("CURRENT_ARR", ascending=False)
            fig = go.Figure(go.Bar(x=owner_data["CURRENT_ARR"], y=owner_data["ACCOUNT_OWNER"], orientation="h",
                marker_color=[COLORS["green"] if v >= 0 else COLORS["red"] for v in owner_data["CURRENT_ARR"]]))
            fig.update_layout(height=350, margin=dict(l=120, r=20, t=10, b=30),
                plot_bgcolor="#FFF", paper_bgcolor="#FFF",
                xaxis=dict(tickformat="$,.0s", gridcolor="#E8E8E8"), yaxis=dict(autorange="reversed"))
            st.plotly_chart(fig, use_container_width=True)

        with col2:
            st.markdown('<p class="visual-title">Customers per Account Owner</p>', unsafe_allow_html=True)
            owner_counts = customers.groupby("ACCOUNT_OWNER").agg(
                CUSTOMERS=("CUSTOMER_ID", "count"), AVG_ARR=("CURRENT_ARR", "mean")).reset_index().sort_values("CUSTOMERS", ascending=False)
            fig = go.Figure(go.Bar(x=owner_counts["CUSTOMERS"], y=owner_counts["ACCOUNT_OWNER"], orientation="h", marker_color=COLORS["blue"]))
            fig.update_layout(height=350, margin=dict(l=120, r=20, t=10, b=30),
                plot_bgcolor="#FFF", paper_bgcolor="#FFF", xaxis=dict(gridcolor="#E8E8E8"), yaxis=dict(autorange="reversed"))
            st.plotly_chart(fig, use_container_width=True)

        st.markdown('<p class="visual-title">ARR Movements by Account Owner</p>', unsafe_allow_html=True)
        if not movements.empty:
            rep_movements = movements.groupby(["ACCOUNT_OWNER", "CLASSIFICATION_GROUP"])["ARR_DELTA"].sum().reset_index()
            pivot = rep_movements.pivot_table(index="ACCOUNT_OWNER", columns="CLASSIFICATION_GROUP", values="ARR_DELTA", fill_value=0)
            pivot["Net"] = pivot.sum(axis=1)
            pivot = pivot.sort_values("Net", ascending=False)
            pivot_display = pivot.applymap(lambda x: f"${x:,.0f}")
            st.dataframe(pivot_display, use_container_width=True)

        st.markdown('<p class="visual-title">Customer Portfolio</p>', unsafe_allow_html=True)
        display_customers = customers[["CUSTOMER_NAME", "INDUSTRY", "SEGMENT", "REGION", "ACCOUNT_OWNER",
            "CURRENT_ARR", "ACTIVE_PRODUCTS", "TENURE_MONTHS"]].copy()
        display_customers["CURRENT_ARR"] = display_customers["CURRENT_ARR"].apply(lambda x: f"${x:,.0f}")
        st.dataframe(display_customers, use_container_width=True, hide_index=True)


# =============================================================
# TAB 4: RETENTION & CHURN
# =============================================================
with tab4:
    retention = data["retention"]
    if retention.empty:
        st.warning("No data for selected filters.")
    else:
        avg_grr = retention["GROSS_RETENTION_RATE"].mean()
        avg_nrr = retention["NET_RETENTION_RATE"].mean()
        total_churn = metrics["CHURN_ARR"].sum() if not metrics.empty else 0
        churned = metrics["CHURNED_CUSTOMERS"].sum() if not metrics.empty else 0

        c1, c2, c3, c4 = st.columns(4)
        with c1:
            st.markdown(f'<div class="kpi-card"><div class="kpi-label">Avg Gross Retention</div><div class="kpi-value">{avg_grr:.1%}</div></div>', unsafe_allow_html=True)
        with c2:
            st.markdown(f'<div class="kpi-card"><div class="kpi-label">Avg Net Retention</div><div class="kpi-value">{avg_nrr:.1%}</div></div>', unsafe_allow_html=True)
        with c3:
            st.markdown(f'<div class="kpi-card"><div class="kpi-label">Total Churn</div><div class="kpi-value" style="color:#D32F2F">${total_churn:,.0f}</div></div>', unsafe_allow_html=True)
        with c4:
            st.markdown(f'<div class="kpi-card"><div class="kpi-label">Churned Logos</div><div class="kpi-value">{int(churned)}</div></div>', unsafe_allow_html=True)

        st.markdown("<br>", unsafe_allow_html=True)

        col1, col2 = st.columns(2)
        with col1:
            st.markdown('<p class="visual-title">Retention Rate Trend (with 3M Rolling Avg)</p>', unsafe_allow_html=True)
            fig = go.Figure()
            fig.add_trace(go.Scatter(x=retention["YEAR_MONTH"], y=retention["GROSS_RETENTION_RATE"],
                mode="lines+markers", line=dict(color=COLORS["blue"], width=2), name="GRR", opacity=0.5))
            fig.add_trace(go.Scatter(x=retention["YEAR_MONTH"], y=retention["GRR_3M_AVG"],
                mode="lines", line=dict(color=COLORS["blue"], width=3), name="GRR (3M Avg)"))
            fig.add_trace(go.Scatter(x=retention["YEAR_MONTH"], y=retention["NET_RETENTION_RATE"],
                mode="lines+markers", line=dict(color=COLORS["orange"], width=2), name="NRR", opacity=0.5))
            fig.add_trace(go.Scatter(x=retention["YEAR_MONTH"], y=retention["NRR_3M_AVG"],
                mode="lines", line=dict(color=COLORS["orange"], width=3), name="NRR (3M Avg)"))
            fig.add_hline(y=1.0, line_dash="dash", line_color="#999", line_width=1)
            fig.update_layout(height=300, margin=dict(l=50, r=20, t=10, b=50),
                plot_bgcolor="#FFF", paper_bgcolor="#FFF", xaxis=dict(tickangle=-45, tickfont=dict(size=9)),
                yaxis=dict(tickformat=".0%", gridcolor="#E8E8E8"),
                legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="left", x=0, font=dict(size=9)))
            st.plotly_chart(fig, use_container_width=True)

        with col2:
            st.markdown('<p class="visual-title">Monthly Churn ($)</p>', unsafe_allow_html=True)
            if not metrics.empty:
                fig = go.Figure(go.Bar(x=metrics["YEAR_MONTH"], y=metrics["CHURN_ARR"].abs(), marker_color=COLORS["red"]))
                fig.update_layout(height=300, margin=dict(l=50, r=20, t=10, b=50),
                    plot_bgcolor="#FFF", paper_bgcolor="#FFF", xaxis=dict(tickangle=-45, tickfont=dict(size=9)),
                    yaxis=dict(tickformat="$,.0s", gridcolor="#E8E8E8"))
                st.plotly_chart(fig, use_container_width=True)

        st.markdown('<p class="visual-title">Subscription Renewal Risk Pipeline</p>', unsafe_allow_html=True)
        if not subscriptions.empty:
            risk_summary = subscriptions.groupby("RENEWAL_RISK").agg(
                COUNT=("SUBSCRIPTION_ID", "count"), ARR_AT_RISK=("ARR", "sum")).reset_index().sort_values("RENEWAL_RISK")
            risk_summary["ARR_AT_RISK"] = risk_summary["ARR_AT_RISK"].apply(lambda x: f"${x:,.0f}")
            st.dataframe(risk_summary, use_container_width=True, hide_index=True)

        st.markdown('<p class="visual-title">Quarterly Strategic Metrics</p>', unsafe_allow_html=True)
        quarterly = data["quarterly"]
        if not quarterly.empty:
            q_display = quarterly[["PERIOD_KEY", "PERIOD_TYPE", "BEGINNING_ARR", "ENDING_ARR",
                "NET_NEW_ARR", "ARR_GROWTH_RATE", "GROSS_RETENTION_RATE", "NET_RETENTION_RATE", "TOTAL_CUSTOMERS"]].copy()
            for col in ["BEGINNING_ARR", "ENDING_ARR", "NET_NEW_ARR"]:
                q_display[col] = q_display[col].apply(lambda x: f"${x:,.0f}")
            for col in ["ARR_GROWTH_RATE", "GROSS_RETENTION_RATE", "NET_RETENTION_RATE"]:
                q_display[col] = q_display[col].apply(lambda x: f"{x:.1%}" if pd.notna(x) else "-")
            st.dataframe(q_display, use_container_width=True, hide_index=True)


# =============================================================
# TAB 5: AI ASSISTANT (Snowflake Cortex)
# =============================================================
with tab5:
    st.markdown('<p class="visual-title">AI Data Assistant</p>', unsafe_allow_html=True)
    st.markdown('<p style="color:#666;font-size:12px;margin-bottom:16px;">Ask questions about your ARR data. Powered by Snowflake Cortex AI.</p>', unsafe_allow_html=True)

    def build_context():
        if metrics.empty:
            return "No data loaded."
        parts = []
        latest = metrics.iloc[-1]
        parts.append(f"Period: {metrics.iloc[0]['YEAR_MONTH']} to {latest['YEAR_MONTH']}")
        parts.append(f"Ending ARR: ${latest['ENDING_ARR']:,.0f}")
        parts.append(f"Total Net New ARR: ${metrics['NET_NEW_ARR'].sum():,.0f}")
        parts.append(f"Total New Business: ${metrics['NEW_BUSINESS_ARR'].sum():,.0f}")
        parts.append(f"Total Churn: ${metrics['CHURN_ARR'].sum():,.0f}")
        parts.append(f"Total Expansion: ${metrics['EXPANSION_ARR'].sum():,.0f}")
        parts.append(f"Avg GRR: {metrics['GROSS_RETENTION_RATE'].mean():.1%}")
        parts.append(f"Avg NRR: {metrics['NET_RETENTION_RATE'].mean():.1%}")
        parts.append(f"Active Customers: {int(latest['CUSTOMER_COUNT'])}")
        if not customers.empty:
            parts.append("\nTop Customers by ARR:")
            top = customers.nlargest(5, "CURRENT_ARR")
            for _, row in top.iterrows():
                parts.append(f"  {row['CUSTOMER_NAME']} ({row['REGION']}): ${row['CURRENT_ARR']:,.0f}")
            region_totals = customers.groupby("REGION")["CURRENT_ARR"].sum().sort_values(ascending=False)
            parts.append("\nARR by Region:")
            for region, val in region_totals.items():
                parts.append(f"  {region}: ${val:,.0f}")
        return "\n".join(parts)

    def get_response(prompt):
        context = build_context()
        try:
            # Cortex Complete via SQL in SPCS
            import json
            prompt_escaped = prompt.replace("'", "''")
            context_escaped = context.replace("'", "''")
            result = run_query(f"""
                SELECT SNOWFLAKE.CORTEX.COMPLETE('llama3.1-70b',
                    '[SYSTEM]You are an ARR data analyst. Answer concisely based on this data:\n{context_escaped}[/SYSTEM]\n[USER]{prompt_escaped}[/USER]'
                ) AS RESPONSE
            """)
            if not result.empty:
                return result.iloc[0]["RESPONSE"]
            return local_answer(prompt)
        except Exception as e:
            # Fallback to local analysis
            return local_answer(prompt)

    def local_answer(prompt):
        p = prompt.lower()
        if metrics.empty:
            return "No data available."
        latest = metrics.iloc[-1]
        if any(k in p for k in ["ending arr", "total arr", "current arr"]):
            return f"The current Ending ARR is **${latest['ENDING_ARR']:,.0f}** as of {latest['YEAR_MONTH']}."
        if any(k in p for k in ["retention", "grr", "nrr"]):
            return (f"**Latest ({latest['YEAR_MONTH']}):** GRR {latest['GROSS_RETENTION_RATE']:.1%}, NRR {latest['NET_RETENTION_RATE']:.1%}\n\n"
                    f"**Averages:** GRR {metrics['GROSS_RETENTION_RATE'].mean():.1%}, NRR {metrics['NET_RETENTION_RATE'].mean():.1%}")
        if any(k in p for k in ["churn", "lost"]):
            return f"**Total Churn:** ${metrics['CHURN_ARR'].sum():,.0f}\n**Churned Logos:** {int(metrics['CHURNED_CUSTOMERS'].sum())}"
        if any(k in p for k in ["new logo", "new business", "new customer"]):
            return f"**Total New Business ARR:** ${metrics['NEW_BUSINESS_ARR'].sum():,.0f}\n**New Customers:** {int(metrics['NEW_CUSTOMERS'].sum())}"
        if any(k in p for k in ["top customer", "biggest", "largest"]):
            if not customers.empty:
                top5 = customers.nlargest(5, "CURRENT_ARR")
                lines = ["**Top 5 Customers by ARR:**"]
                for i, (_, row) in enumerate(top5.iterrows(), 1):
                    lines.append(f"{i}. {row['CUSTOMER_NAME']} ({row['SEGMENT']}, {row['REGION']}): ${row['CURRENT_ARR']:,.0f}")
                return "\n".join(lines)
        if any(k in p for k in ["region", "geo"]):
            if not customers.empty:
                region_totals = customers.groupby("REGION")["CURRENT_ARR"].sum().sort_values(ascending=False)
                lines = ["**Current ARR by Region:**"]
                for region, val in region_totals.items():
                    lines.append(f"- {region}: ${val:,.0f}")
                return "\n".join(lines)
        if any(k in p for k in ["summary", "overview", "how"]):
            return (f"**ARR Overview ({metrics.iloc[0]['YEAR_MONTH']} – {latest['YEAR_MONTH']}):**\n"
                    f"- Ending ARR: ${latest['ENDING_ARR']:,.0f}\n"
                    f"- Net New: ${metrics['NET_NEW_ARR'].sum():,.0f}\n"
                    f"- New Business: ${metrics['NEW_BUSINESS_ARR'].sum():,.0f}\n"
                    f"- Expansion: ${metrics['EXPANSION_ARR'].sum():,.0f}\n"
                    f"- Churn: ${metrics['CHURN_ARR'].sum():,.0f}\n"
                    f"- Customers: {int(latest['CUSTOMER_COUNT'])}\n"
                    f"- Avg GRR: {metrics['GROSS_RETENTION_RATE'].mean():.1%}\n"
                    f"- Avg NRR: {metrics['NET_RETENTION_RATE'].mean():.1%}")
        return ("I can answer about: **Ending ARR**, **Retention rates**, **Churn**, "
                "**New Business**, **Top customers**, **Regions**, or give a **Summary**.")

    if "messages" not in st.session_state:
        st.session_state.messages = []
    for msg in st.session_state.messages:
        with st.chat_message(msg["role"]):
            st.markdown(msg["content"])
    if prompt := st.chat_input("Ask about your ARR data..."):
        st.session_state.messages.append({"role": "user", "content": prompt})
        with st.chat_message("user"):
            st.markdown(prompt)
        with st.chat_message("assistant"):
            with st.spinner("Analyzing..."):
                response = get_response(prompt)
            st.markdown(response)
            st.session_state.messages.append({"role": "assistant", "content": response})
    if not st.session_state.messages:
        st.markdown("---")
        st.markdown('<p style="color:#666;font-size:12px;">Try asking:</p>', unsafe_allow_html=True)
        suggestions = ["What is our current ending ARR?", "How are retention rates trending?",
                       "Who are the top 5 customers?", "Give me an ARR summary",
                       "What does churn look like?", "Break down ARR by region"]
        cols = st.columns(3)
        for i, s in enumerate(suggestions):
            with cols[i % 3]:
                if st.button(s, key=f"sug_{i}", use_container_width=True):
                    st.session_state.messages.append({"role": "user", "content": s})
                    st.rerun()


# =============================================================
# TAB 6: DATA CATALOG
# =============================================================
with tab6:
    st.markdown('<p class="visual-title">Data Catalog — ARR_WAREHOUSE.ARR_ANALYTICS</p>', unsafe_allow_html=True)
    st.markdown('<p style="color:#666;font-size:12px;margin-bottom:16px;">Complete inventory of tables, views, columns, and sample data.</p>', unsafe_allow_html=True)

    @st.cache_data(ttl=600)
    def load_catalog():
        objects = run_query("""
            SELECT TABLE_TYPE, TABLE_NAME, ROW_COUNT, COMMENT
            FROM ARR_WAREHOUSE.INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = 'ARR_ANALYTICS' ORDER BY TABLE_TYPE, TABLE_NAME
        """)
        columns = run_query("""
            SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COMMENT
            FROM ARR_WAREHOUSE.INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = 'ARR_ANALYTICS' ORDER BY TABLE_NAME, ORDINAL_POSITION
        """)
        fks = run_query("""
            SELECT TC.TABLE_NAME, TC.CONSTRAINT_NAME, TC.CONSTRAINT_TYPE
            FROM ARR_WAREHOUSE.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC
            WHERE TC.TABLE_SCHEMA = 'ARR_ANALYTICS'
            AND TC.CONSTRAINT_TYPE IN ('PRIMARY KEY', 'FOREIGN KEY')
            ORDER BY TC.TABLE_NAME, TC.CONSTRAINT_TYPE
        """)
        return objects, columns, fks

    catalog_objects, catalog_columns, catalog_fks = load_catalog()

    tables_df = catalog_objects[catalog_objects["TABLE_TYPE"] == "BASE TABLE"]
    views_df = catalog_objects[catalog_objects["TABLE_TYPE"] == "VIEW"]
    total_rows = tables_df["ROW_COUNT"].sum()
    total_columns = len(catalog_columns)

    c1, c2, c3, c4 = st.columns(4)
    with c1:
        st.markdown(f'<div class="kpi-card"><div class="kpi-label">Tables</div><div class="kpi-value">{len(tables_df)}</div></div>', unsafe_allow_html=True)
    with c2:
        st.markdown(f'<div class="kpi-card"><div class="kpi-label">Views</div><div class="kpi-value">{len(views_df)}</div></div>', unsafe_allow_html=True)
    with c3:
        st.markdown(f'<div class="kpi-card"><div class="kpi-label">Total Rows</div><div class="kpi-value">{int(total_rows):,}</div></div>', unsafe_allow_html=True)
    with c4:
        st.markdown(f'<div class="kpi-card"><div class="kpi-label">Total Columns</div><div class="kpi-value">{int(total_columns)}</div></div>', unsafe_allow_html=True)

    st.markdown("<br>", unsafe_allow_html=True)

    st.markdown('<p class="visual-title">Tables</p>', unsafe_allow_html=True)
    tables_display = tables_df[["TABLE_NAME", "ROW_COUNT", "COMMENT"]].copy()
    tables_display["ROW_COUNT"] = tables_display["ROW_COUNT"].apply(lambda x: f"{int(x):,}")
    st.dataframe(tables_display, use_container_width=True, hide_index=True)

    st.markdown('<p class="visual-title">Views</p>', unsafe_allow_html=True)
    views_display = views_df[["TABLE_NAME", "COMMENT"]].copy()
    views_display["COMMENT"] = views_display["COMMENT"].fillna("-")
    st.dataframe(views_display, use_container_width=True, hide_index=True)

    st.markdown("<br>", unsafe_allow_html=True)
    st.markdown('<p class="visual-title">Primary Keys & Foreign Keys</p>', unsafe_allow_html=True)
    if not catalog_fks.empty:
        st.dataframe(catalog_fks, use_container_width=True, hide_index=True)

    st.markdown("<br>", unsafe_allow_html=True)
    st.markdown('<p class="visual-title">Explore Table or View</p>', unsafe_allow_html=True)
    all_objects = catalog_objects["TABLE_NAME"].tolist()
    selected_object = st.selectbox("Select a table or view to explore:", all_objects, key="catalog_select")

    if selected_object:
        obj_columns = catalog_columns[catalog_columns["TABLE_NAME"] == selected_object]
        st.markdown(f'<p style="color:#333;font-size:12px;font-weight:600;margin-top:10px;">Columns in {selected_object} ({len(obj_columns)} columns)</p>', unsafe_allow_html=True)
        col_display = obj_columns[["COLUMN_NAME", "DATA_TYPE", "IS_NULLABLE", "COMMENT"]].copy()
        col_display["COMMENT"] = col_display["COMMENT"].fillna("-")
        st.dataframe(col_display, use_container_width=True, hide_index=True)

        st.markdown(f'<p style="color:#333;font-size:12px;font-weight:600;margin-top:10px;">Sample Data (Top 20 rows)</p>', unsafe_allow_html=True)
        try:
            sample = run_query(f"SELECT * FROM {selected_object} LIMIT 20")
            st.dataframe(sample, use_container_width=True, hide_index=True)
        except Exception as e:
            st.error(f"Could not query {selected_object}: {e}")

    st.markdown("<br>", unsafe_allow_html=True)
    st.markdown('<p class="visual-title">Relationship Map</p>', unsafe_allow_html=True)
    rel_data = pd.DataFrame({
        "From Table": ["FACT_CONTRACT", "FACT_CONTRACT_LINE", "FACT_CONTRACT_LINE", "FACT_SUBSCRIPTION",
            "FACT_SUBSCRIPTION", "FACT_SUBSCRIPTION", "FACT_ARR_MONTHLY_SNAPSHOT",
            "FACT_ARR_MONTHLY_SNAPSHOT", "FACT_ARR_MONTHLY_SNAPSHOT", "FACT_ARR_MOVEMENT",
            "FACT_ARR_MOVEMENT", "FACT_ARR_MOVEMENT", "FACT_ARR_MOVEMENT",
            "FACT_ARR_ADJUSTMENT", "FACT_ARR_ADJUSTMENT", "FACT_ARR_METRICS"],
        "FK Column": ["CUSTOMER_ID", "CONTRACT_ID", "PRODUCT_ID", "CUSTOMER_ID",
            "CONTRACT_LINE_ID", "PRODUCT_ID", "CUSTOMER_ID",
            "PRODUCT_ID", "DATE_KEY", "CUSTOMER_ID",
            "PRODUCT_ID", "CLASSIFICATION_ID", "DATE_KEY",
            "CUSTOMER_ID", "DATE_KEY", "DATE_KEY"],
        "To Table": ["DIM_CUSTOMER", "FACT_CONTRACT", "DIM_PRODUCT", "DIM_CUSTOMER",
            "FACT_CONTRACT_LINE", "DIM_PRODUCT", "DIM_CUSTOMER",
            "DIM_PRODUCT", "DIM_TIME", "DIM_CUSTOMER",
            "DIM_PRODUCT", "DIM_ARR_CLASSIFICATION", "DIM_TIME",
            "DIM_CUSTOMER", "DIM_TIME", "DIM_TIME"],
        "Cardinality": ["Many:1"] * 16,
    })
    st.dataframe(rel_data, use_container_width=True, hide_index=True)
