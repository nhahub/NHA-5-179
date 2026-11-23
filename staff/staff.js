"use strict";

const labels = {
  skip: ["Skip to content", "انتقل إلى المحتوى"], admin: ["Admin", "مسؤول العيادة"], doctor: ["Doctor", "الطبيب"],
  login: ["Staff sign in", "دخول الموظفين"], loginHelp: ["Sign in with your ClinicOS demo staff account.", "سجّل الدخول بحساب موظف ClinicOS التجريبي."],
  email: ["Email", "البريد الإلكتروني"], password: ["Password", "كلمة المرور"], signIn: ["Sign in", "تسجيل الدخول"], signOut: ["Sign out", "تسجيل الخروج"],
  title: ["Care Board", "لوحة المتابعة"], visits: ["My visits", "زياراتي"], patientChannel: ["Patients use Telegram", "المرضى يستخدمون تيليجرام"],
  patientHelp: ["Patients book appointments and receive their files through the clinic bot.", "يحجز المرضى المواعيد ويتلقّون ملفاتهم عبر بوت العيادة."],
  date: ["Date · Cairo time", "التاريخ · بتوقيت القاهرة"], refresh: ["Refresh", "تحديث"], today: ["Today", "اليوم"], empty: ["No appointments", "لا توجد مواعيد"],
  booked: ["Booked", "محجوز"], checked_in: ["Checked in", "تم تسجيل الحضور"], in_visit: ["In visit", "الزيارة جارية"],
  completed: ["Completed", "مكتملة"], cancelled: ["Cancelled", "ملغاة"], no_show: ["No-show", "لم يحضر"], closed: ["Closed", "منتهية"],
  board: ["Appointments", "المواعيد"], booking: ["Availability and booking", "المواعيد المتاحة والحجز"], catalog: ["Services", "الخدمات"],
  reports: ["Daily report", "التقرير اليومي"], operations: ["Support handoffs", "طلبات المتابعة"], patient: ["Patient", "المريض"],
  select: ["Select", "اختر"], checkIn: ["Check in", "سجّل الحضور"], cancelBooking: ["Cancel appointment", "ألغِ الموعد"],
  reschedule: ["Reschedule", "غيّر الموعد"], available: ["Find available slots", "ابحث عن المواعيد المتاحة"], book: ["Book appointment", "احجز موعدًا"],
  slot: ["Time slot", "الفترة المتاحة"], startTime: ["Start time", "وقت البدء"], endTime: ["End time", "وقت الانتهاء"],
  invoice: ["Invoice", "الفاتورة"], awaiting: ["Invoice pending. Refresh after the billing worker runs.", "الفاتورة قيد الإنشاء. حدّث الصفحة بعد عمل نظام الفوترة."],
  total: ["Total", "الإجمالي"], paid: ["Paid", "المدفوع"], balance: ["Balance", "المتبقي"], pay: ["Record payment", "سجّل دفعة"],
  amount: ["Amount (EGP)", "المبلغ بالجنيه المصري"], method: ["Method", "طريقة الدفع"], cash: ["Cash", "نقدًا"], card: ["Card", "بطاقة"],
  transfer: ["Bank transfer", "تحويل بنكي"], reference: ["Reference (optional)", "المرجع (اختياري)"],
  code: ["Service code", "رمز الخدمة"], serviceName: ["Service name", "اسم الخدمة"], active: ["Active", "نشطة"],
  editService: ["Edit service", "عدّل الخدمة"], createService: ["Add service", "أضف خدمة"], save: ["Save", "احفظ"],
  loadReport: ["Load daily report", "اعرض التقرير اليومي"], billed: ["Billed", "المفوتر"], collected: ["Collected", "المحصّل"],
  reportBasis: ["By appointment date", "حسب تاريخ الموعد"],
  outstanding: ["Outstanding", "المستحق"], assign: ["Assign to me", "أسند إليّ"], resolve: ["Resolve", "أنهِ الطلب"],
  reportAppointments: ["Appointments", "المواعيد"], reportNoShows: ["No-shows", "حالات عدم الحضور"],
  noHandoffs: ["No open handoffs", "لا توجد طلبات مفتوحة"], handoff: ["Support request", "طلب متابعة"], low_feedback: ["Low feedback", "تقييم منخفض"],
  faq: ["FAQ request", "سؤال يحتاج متابعة"], invoiceFailures: ["Invoice failures", "حالات فشل الفواتير"],
  workflowFailures: ["Workflow failures", "حالات فشل الأتمتة"], waitCheckIn: ["The admin needs to check in this patient.", "على مسؤول العيادة تسجيل حضور المريض."],
  start: ["Start visit", "ابدأ الزيارة"], chart: ["Visit notes", "ملاحظات الزيارة"], revision: ["Revision", "المراجعة"],
  amend: ["Save amendment", "احفظ التعديل"], editNotes: ["Notes", "الملاحظات"], files: ["Patient files", "ملفات المريض"],
  private: ["Private attachment", "مرفق خاص"], noFiles: ["No files attached.", "لا توجد ملفات مرفقة."],
  uploadHint: ["Save notes first to create a revision. PDF, PNG or JPEG up to 5 MiB.", "احفظ الملاحظات أولًا لإنشاء مراجعة. PDF أو PNG أو JPEG حتى ٥ ميبيبايت."],
  fileHint: ["PDF, PNG or JPEG up to 5 MiB.", "PDF أو PNG أو JPEG حتى ٥ ميبيبايت."], upload: ["Upload file", "ارفع ملفًا"],
  download: ["Download", "نزّل"], send: ["Send to patient", "أرسل إلى المريض"], sent: ["Accepted by Telegram", "تم قبول الإرسال عبر تيليجرام"],
  sending: ["Sending", "جارٍ الإرسال"], delivery_unknown: ["Delivery uncertain. Check with the patient before sending again.", "حالة الإرسال غير مؤكدة. تحقّق مع المريض قبل إعادة الإرسال."],
  failed: ["File was not sent. Check the link and try again.", "لم يُرسل الملف. تحقّق من الربط وحاول مرة أخرى."],
  noChat: ["The patient needs an eligible linked private Telegram chat to receive files.", "يحتاج المريض إلى محادثة تيليجرام خاصة ومربوطة ومؤهلة لاستلام الملفات."],
  summary: ["Visit summary", "ملخص الزيارة"], generate: ["Generate draft", "أنشئ مسودة"], summaryText: ["Summary text", "نص الملخص"],
  printSummary: ["Print approved summary", "اطبع الملخص المعتمد"],
  summaryUnavailable: ["The local summary service did not respond. Check Ollama and try again.", "لم تستجب خدمة الملخص المحلية. تحقّق من Ollama وحاول مجددًا."],
  saveNotesFirst: ["Save the visit notes first.", "احفظ ملاحظات الزيارة أولًا."],
  approve: ["Approve", "اعتمد"], reject: ["Reject", "ارفض"], approved: ["Approved", "معتمد"], rejected: ["Rejected", "مرفوض"], draft: ["Draft", "مسودة"],
  followup: ["Follow-up date", "تاريخ المتابعة"], finalize: ["Finalize visit", "أنهِ الزيارة"], performed: ["Services performed", "الخدمات المقدمة"],
  followups: ["Follow-ups due", "المتابعات المستحقة"], followupReview: ["Needs doctor confirmation", "بانتظار تأكيد الطبيب"],
  followupAppointment: ["Follow-up appointment", "موعد متابعة"], followupSave: ["Book follow-up", "احجز موعد المتابعة"],
  followupMove: ["Reschedule follow-up", "غيّر موعد المتابعة"], followupSaved: ["Follow-up booked.", "تم حجز موعد المتابعة."],
  followupDateError: ["Choose a date no earlier than today or this visit.", "اختر تاريخًا لا يسبق اليوم أو تاريخ هذه الزيارة."],
  followupSlotError: ["This slot is unavailable. Find available slots again.", "هذه الفترة غير متاحة. ابحث عن الفترات المتاحة مرة أخرى."],
  followupClosed: ["This follow-up appointment can no longer be moved.", "لا يمكن تغيير موعد هذه المتابعة."],
  quantity: ["Quantity", "الكمية"], confirm: ["Confirm", "أكّد"], cancel: ["Cancel", "إلغاء"],
  confirmSend: ["Send this file via Telegram to", "أرسل هذا الملف عبر تيليجرام إلى"],
  confirmVisit: ["Finalize the visit and queue an invoice for", "أنهِ الزيارة وجهّز الفاتورة لـ"],
  confirmCancel: ["Cancel the appointment for", "ألغِ الموعد لـ"], confirmPayment: ["Record this payment for", "سجّل هذه الدفعة لـ"],
  working: ["Working…", "جارٍ التنفيذ…"], done: ["Saved.", "تم الحفظ."],
  unavailable: ["This action needs the n8n webhook. Publish the approved demo workflow, or arm this route in n8n test mode.", "يحتاج هذا الإجراء إلى رابط n8n. انشر سير العمل التجريبي المعتمد أو شغّل هذا الرابط في وضع الاختبار."],
  upstream: ["The clinic service did not respond. Try again after checking the local workflow.", "لم تستجب خدمة العيادة. تحقّق من سير العمل المحلي ثم حاول مجددًا."],
  signInAgain: ["Your session ended. Sign in again.", "انتهت جلستك. سجّل الدخول مجددًا."],
  badLogin: ["Email or password is incorrect.", "البريد الإلكتروني أو كلمة المرور غير صحيحة."],
  forbidden: ["This account cannot perform that action.", "لا يملك هذا الحساب صلاحية تنفيذ الإجراء."],
  actionFailed: ["The action could not be completed. Check the details and refresh.", "تعذّر إكمال الإجراء. تحقّق من التفاصيل وحدّث الصفحة."],
  invalid: ["Check the form values and try again.", "تحقّق من الحقول وحاول مجددًا."], fileError: ["Choose a PDF, PNG or JPEG up to 5 MiB.", "اختر PDF أو PNG أو JPEG حتى ٥ ميبيبايت."],
  noSlots: ["No slots available for this date.", "لا توجد فترات متاحة في هذا التاريخ."],
  addServices: ["Enter a quantity for at least one service.", "أدخل كمية لخدمة واحدة على الأقل."],
};
const app = document.querySelector("#app");
const dialog = document.querySelector("#confirm");
const announce = document.querySelector("#announce");
let lang = localStorage.getItem("clinicos-language") === "ar" ? "ar" : "en";
let role, board, chart, selected, slots, followupSlots, report, handoffs, catalogCode, status;
let busy = false;
let page = "board";
let date = null;
let resolveConfirm;
const requestIds = new Map();
const t = key => labels[key]?.[lang === "ar" ? 1 : 0] ?? key;
const esc = value => String(value ?? "").replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"})[c]);
const safeName = value => `<bdi>${esc(value)}</bdi>`;
const time = value => String(value ?? "").slice(0,5);
const currency = value => new Intl.NumberFormat(lang === "ar" ? "ar-EG" : "en-EG", {style:"currency",currency:"EGP"}).format(value);
const calendarDate = value => new Intl.DateTimeFormat(lang === "ar" ? "ar-EG" : "en-GB",
  {dateStyle:"medium",timeZone:"UTC"}).format(new Date(value + "T00:00:00Z"));
const button = (key, action = key, value = "", primary = false) => `<button type="button" data-action="${action}" data-value="${esc(value)}" ${primary ? 'class="primary"' : ""}>${t(key)}</button>`;
const submit = key => `<button class="primary" type="submit">${t(key)}</button>`;
const chip = key => `<span class="chip">${t(key)}</span>`;
const msg = key => `<p class="muted">${t(key)}</p>`;
const input = (key, name, attrs = "") => `<label>${t(key)}<input name="${name}" ${attrs}></label>`;
const options = (items, label) => `<option value="">${t("select")}</option>${items.map(item => `<option value="${esc(item.id)}">${esc(label(item))}</option>`).join("")}`;
const panel = (key, body) => `<section class="surface flow"><h2>${t(key)}</h2>${body}</section>`;
const appointment = () => board?.appointments.find(a => a.id === selected);
const lane = a => a.status === "checked_in" && a.started ? "in_visit" : a.status;
const appointmentName = a => `<strong>${safeName(a.patient)}</strong>`;

function message(key, error = false) {
  status = {key, error};
  announce.textContent = t(key);
}

async function fetchApi(key, body = {}, binary = false) {
  const multipart = body instanceof FormData;
  const response = await fetch("/api/" + key, {
    method: "POST", credentials: "same-origin",
    headers: multipart ? {} : {"Content-Type":"application/json"},
    body: multipart ? body : JSON.stringify(body),
  });
  if (binary && response.ok) return response.blob();
  const data = await response.json();
  if (!response.ok) {
    if (response.status === 401 && key !== "login") {
      role = null; board = null; chart = null; selected = null;
    }
    throw new Error(data.code);
  }
  return data;
}

const errorLabels = {
  INVALID_LOGIN:"badLogin", SIGN_IN_REQUIRED:"signInAgain", FORBIDDEN:"forbidden",
  forbidden_or_not_found:"forbidden", forbidden_or_invalid_state:"forbidden",
  WORKFLOW_NOT_AVAILABLE:"unavailable", UPSTREAM_UNAVAILABLE:"upstream", NO_LINKED_CHAT:"noChat",
  DELIVERY_UNCERTAIN:"delivery_unknown", delivery_unknown:"delivery_unknown", failed:"failed", sending:"sending",
  VALIDATION_ERROR:"invalid", FILE_TYPE:"fileError", unsupported_file_type:"fileError", FILE_TOO_LARGE:"fileError",
  file_too_large_max_5mb:"fileError", REVISION_REQUIRED:"saveNotesFirst", SUMMARY_UNAVAILABLE:"summaryUnavailable",
  FOLLOWUP_DATE:"followupDateError", FOLLOWUP_SLOT_UNAVAILABLE:"followupSlotError",
  FOLLOWUP_CLOSED:"followupClosed", FOLLOWUP_SLOT_REQUIRED:"followupSlotError",
};

async function perform(fn) {
  if (busy) return;
  const scope = document.querySelector("main");
  const values = formValues();
  busy = true;
  status = null;
  scope?.setAttribute("aria-busy","true");
  document.querySelector("#working").hidden = false;
  announce.textContent = t("working");
  try {
    await fn();
  } catch (error) {
    message(errorLabels[error.message] ?? "actionFailed", true);
  } finally {
    busy = false;
    render();
    if (status?.error) restoreForms(values);
    if (status) document.querySelector("#status")?.focus();
  }
}

async function loadBoard() {
  board = await fetchApi("board", {p_date:date});
  date = board.date;
  selected = appointment()?.id ?? board.appointments[0]?.id;
  await loadChart();
}

async function loadChart() {
  const id = appointment()?.visit_id;
  chart = role === "doctor" && id ? await fetchApi("files",{p_visit:id}) : null;
}

function login() {
  return `<section class="login" aria-labelledby="title">
    <div class="login-form">
      <h1 id="title">${t("login")}</h1><p class="muted">${t("loginHelp")}</p>
      <form class="flow signin" data-form="login">
        ${input("email","email",'type="email" autocomplete="username" maxlength="254" required dir="ltr"')}
        ${input("password","password",'type="password" autocomplete="current-password" maxlength="1024" required')}
        ${submit("signIn")}
      </form>
    </div>
    <div class="login-visual"><h2>${t("title")}</h2>
      <p class="signin-note">${t("patientHelp")}</p><p>${t("patientChannel")}</p>
    </div>
  </section>`;
}

function row(a, showDoctor) {
  return `<button class="row" type="button" data-action="choose" data-value="${esc(a.id)}" aria-pressed="${a.id === selected}">
    <time dir="ltr">${time(a.start)}</time><span>${appointmentName(a)}
      ${a.is_followup ? `<br><small>${t("followupAppointment")}</small>` : ""}</span>
    <small>${showDoctor ? safeName(a.doctor) : t(lane(a))}</small></button>`;
}

function appointmentBoard() {
  const list = board?.appointments ?? [];
  if (!list.length) return panel("board",msg("empty"));
  if (role === "doctor") return panel("visits",`<div class="visit-strip">${list.map(a=>row(a,false)).join("")}</div>`);
  return `<section class="surface"><h2>${t("board")}</h2><div class="board-columns">
    ${["booked","checked_in","in_visit","closed"].map(key => {
      const inLane = list.filter(a => key === "closed" ? ["completed","cancelled","no_show"].includes(lane(a)) : lane(a) === key);
      return `<section class="lane"><h3>${t(key)}</h3>${inLane.map(a=>row(a,true)).join("") || `<small>${t("empty")}</small>`}</section>`;
    }).join("")}
  </div></section>`;
}

function metrics(values) {
  return `<dl class="summary">${values.map(([key,val])=>`<div><dt>${t(key)}</dt><dd>${safeName(val)}</dd></div>`).join("")}</dl>`;
}

function invoice(a) {
  if (!a.invoice) return a.status === "completed" ? `<section class="detail-section"><h3>${t("invoice")}</h3>${msg("awaiting")}</section>` : "";
  const {total,paid,balance} = a.invoice;
  return `<section class="detail-section"><h3>${t("invoice")}</h3>
    ${metrics([["total",currency(total)],["paid",currency(paid)],["balance",currency(balance)]])}
    ${Number(balance) > 0 ? `<form class="form-grid" data-form="payment">
      ${input("amount","amount",`type="number" min="0.01" max="${esc(balance)}" step="0.01" value="${esc(balance)}" required`)}
      <label>${t("method")}<select name="method">${["cash","card","transfer"].map(v=>`<option value="${v}">${t(v)}</option>`).join("")}</select></label>
      ${input("reference","reference",'maxlength="150"')}${submit("pay")}</form>` : ""}
  </section>`;
}

function followupsDue() {
  const items = board?.followups ?? [];
  if (!items.length) return "";
  return panel("followups", items.map(f => `<div class="status-line section-head">
    <div><strong>${safeName(f.patient)}</strong><br><small>${safeName(f.doctor)}</small></div>
    ${f.needs_review ? chip("followupReview") : safeName(calendarDate(f.due_date))}
  </div>`).join(""));
}

function followupDateAndTime(followup) {
  return safeName(calendarDate(followup.due_date))
    + (followup.start && followup.end ? " · " + safeName(time(followup.start) + "–" + time(followup.end)) : "");
}

function clearFollowupSlots() {
  followupSlots=null;
  const selection=document.querySelector("#followup-selection");
  if (selection) selection.hidden=true;
}

function adminDetail(a) {
  return `
    ${a.status === "booked" ? `<div class="detail-section">
      <div class="actions">${button("checkIn","checkIn","",true)}${button("cancelBooking")}</div>
      <form class="form-grid" data-form="reschedule">
        ${input("date","date",`type="date" value="${esc(date)}" required`)}
        ${input("startTime","start",`type="time" value="${time(a.start)}" required`)}
        ${input("endTime","end",`type="time" value="${time(a.end)}" required`)}
        ${submit("reschedule")}
      </form></div>` : ""}
    ${a.followup ? `<section class="detail-section">
      <div class="section-head"><h3>${t("followup")}</h3>${a.followup.needs_review ? chip("followupReview") : ""}</div>
      <p>${followupDateAndTime(a.followup)} ${a.followup.status ? chip(a.followup.status) : ""}</p>
    </section>` : ""}
    ${invoice(a)}`;
}

function noteData() {
  try { return JSON.parse(chart?.revision?.content ?? "{}"); }
  catch { return {}; }
}

function summaryDraft() {
  const draft = chart?.summary;
  const view = draft?.state === "draft" ? `<form data-form="summary-review" class="flow">
      <label>${t("summaryText")}<textarea name="text" maxlength="12000" required>${esc(draft.text)}</textarea></label>
      <div class="actions">${submit("save")}${button("approve")}${button("reject")}</div></form>` :
    draft ? `<p class="text-block">${esc(draft.text)}</p>` : "";
  return `<section class="detail-section"><div class="section-head"><h3>${t("summary")}</h3>${draft ? chip(draft.state) : ""}</div>
    ${view}${!draft ? `<div class="actions">${button("generate")}</div>`
      : draft.state === "approved" ? `<div class="actions">${button("printSummary")}</div>` : ""}
  </section>`;
}

function attachments() {
  const upload = chart?.revision
    ? `<form class="form-grid" data-form="upload">
        ${input("files","file",'type="file" accept="application/pdf,image/png,image/jpeg,.pdf,.png,.jpg,.jpeg" required')}
        ${submit("upload")}
      </form>${msg("fileHint")}` : msg("uploadHint");
  const fileRows = (chart?.files ?? []).map(f => `<div class="file-line">
    <div><strong>${safeName(f.name)}</strong><small>${t(f.state === "accepted" ? "sent" : f.state || "private")}</small></div>
    <div class="actions">${button("download","download",f.id)}
    ${chart.can_send && !["accepted","sending","delivery_unknown"].includes(f.state) ? button("send","send",f.id,true) : ""}</div>
  </div>`).join("");
  return `<section class="detail-section"><h3>${t("files")}</h3>
    ${upload}${chart && !chart.can_send ? msg("noChat") : ""}
    ${fileRows || msg("noFiles")}
  </section>`;
}

function doctorFollowup(a) {
  const current = a.followup;
  const available = followupSlots?.visitId === a.visit_id ? followupSlots : null;
  const canBook = !current?.status || ["booked","cancelled"].includes(current.status);
  return `<section class="detail-section">
    <div class="section-head"><h3>${t("followupAppointment")}</h3>${current?.needs_review ? chip("followupReview") : ""}</div>
    ${current ? `<p>${followupDateAndTime(current)} ${current.status ? chip(current.status) : ""}</p>` : ""}
    ${canBook ? `<form data-form="followup-slots" class="form-grid">
      ${input("followup","date",`type="date" value="${esc(available?.date ?? current?.due_date ?? date)}" required`)}
      ${submit("available")}</form>
    ${available ? `<div id="followup-selection">${available.items.length ? `<form data-form="followup" class="form-grid">
      <label>${t("slot")} · ${safeName(calendarDate(available.date))}
        <select name="slot" required>${options(available.items.map((s,i)=>({...s,id:String(i)})),
          s=>time(s.start_time)+"–"+time(s.end_time))}</select></label>
      ${submit(current?.status === "booked" ? "followupMove" : "followupSave")}
    </form>` : msg("noSlots")}</div>` : ""}` : ""}
  </section>`;
}

function doctorDetail(a) {
  if (!a.visit_id) return `<div class="detail-section">${msg("waitCheckIn")}</div>`;
  if (!a.started && !a.finalized) return `<div class="detail-section"><div class="actions">${button("start","start","",true)}</div></div>`;
  if (!chart) return msg("upstream");
  return `<section class="detail-section"><div class="section-head"><h3>${t("chart")}</h3>
    ${chart.revision ? `<small>${t("revision")} ${esc(chart.revision.number)}</small>` : ""}</div>
    <form data-form="notes" class="flow"><label>${t("editNotes")}<textarea name="notes" maxlength="12000" required>${esc(noteData()?.notes)}</textarea></label>
      <div class="actions">${submit(a.finalized ? "amend" : "save")}</div></form>
    </section>
    ${attachments()}
    ${chart.revision ? summaryDraft() : ""}
    ${chart.revision ? doctorFollowup(a) : ""}
    ${chart.revision && !a.finalized && board.services.length ? `<section class="detail-section">
      <h3>${t("performed")}</h3><form class="flow" data-form="finalize">
        <div class="form-grid">${board.services.map(s=>`<label>${safeName(s.name)}
          <input type="number" name="${esc(s.code)}" min="0" max="100" step="1" value="0" aria-label="${esc(t("quantity")+" "+s.name)}"></label>`).join("")}</div>
        <div class="actions">${submit("finalize")}</div></form></section>` : ""}`;
}

function detail(a) {
  return a ? `<section class="surface detail" id="patient" tabindex="-1">
  <div class="section-head"><h2>${safeName(a.patient)}</h2><div class="actions">${a.is_followup ? chip("followupAppointment") : ""}${chip(lane(a))}</div></div>
    <p class="muted"><bdi>${time(a.start)}–${time(a.end)}</bdi> · ${safeName(a.doctor)}</p>
    ${role === "admin" ? adminDetail(a) : doctorDetail(a)}
  </section>` : "";
}

function booking() {
  const doctorOptions=options(board?.doctors ?? [], d=>d.name);
  const patientOptions=options(board?.patients ?? [], p=>p.dob ? p.name+" · "+p.dob : p.name);
  return panel("booking",`<form class="form-grid" data-form="availability">
      <label>${t("doctor")}<select name="doctor" required>${doctorOptions}</select></label>
      ${input("date","date",`type="date" value="${esc(date)}" required`)}
      ${submit("available")}</form>
    ${slots ? slots.items.length ? `<form class="form-grid" data-form="book">
      <label>${t("patient")}<select name="patient" required>${patientOptions}</select></label>
      <label>${t("slot")}<select name="slot" required>${options(slots.items.map((s,i)=>({...s,id:String(i)})), s=>time(s.start_time)+"–"+time(s.end_time))}</select></label>
      ${submit("book")}</form>` : msg("noSlots") : ""}`);
}

function catalog() {
  const services = board?.services ?? [];
  const item = services.find(s => s.code === catalogCode);
  return panel("catalog",`<form class="flow" data-form="catalog">
    <label class="text-field">${t("editService")}<select id="service-picker">
      <option value="">${t("createService")}</option>
      ${services.map(s=>`<option value="${esc(s.code)}" ${item?.code === s.code ? "selected" : ""}>${esc(s.name)} · ${esc(s.code)}</option>`).join("")}
    </select></label>
    <div class="form-grid">
      ${input("code","code",`value="${esc(item?.code)}" maxlength="100" required ${item ? "readonly" : ""}`)}
      ${input("serviceName","name",`value="${esc(item?.name)}" maxlength="200" required`)}
      ${input("amount","price",`type="number" min="0" step="0.01" max="9999999999.99" value="${esc(item?.price)}" required`)}
      <label class="checkbox"><input type="checkbox" name="active" ${item?.active ?? true ? "checked" : ""}>${t("active")}</label>
      ${submit("save")}</div></form>`);
}

function reports() {
  return panel("reports",`<p class="muted">${t("reportBasis")}${date ? " · " + safeName(calendarDate(date)) : ""}</p>
    <div class="actions">${button("loadReport","loadReport","",true)}</div>
    ${report ? metrics([["reportAppointments",report.appointments],["reportNoShows",report.no_shows],
      ["billed",currency(report.billed)],["collected",currency(report.collected)],
      ["outstanding",currency(report.outstanding)],["invoiceFailures",report.pending_invoice_failures]]) : ""}`);
}

function operations() {
  const names = new Map((board?.patients ?? []).map(p=>[p.id,p.name]));
  const list = handoffs?.handoffs.map(h=>`<div class="status-line section-head"><div>
    <strong>${safeName(names.get(h.patient_id) ?? t("patient"))}</strong><br><small>${t(labels[h.kind] ? h.kind : "handoff")}</small></div>
    <div class="actions">${button("assign","assign",h.id)}${button("resolve","resolve",h.id)}</div></div>`).join("");
  return panel("operations",`<div class="actions">${button("refresh","loadOperations","",true)}</div>
    ${handoffs ? (list || msg("noHandoffs")) + metrics([["invoiceFailures",handoffs.invoice_failures?.length ?? 0],
      ["workflowFailures",handoffs.workflow_failures?.length ?? 0]]) : ""}`);
}

function workspace() {
  return `<div class="page-head section-head"><h1>${t(role === "admin" ? "title" : "visits")}</h1>
    <form class="date-control" data-form="date">
      ${input("date","date",`id="board-date" type="date" value="${esc(date)}" required`)}${submit("refresh")}
    </form></div>
    ${role === "admin" ? `<nav aria-label="${t("title")}" class="nav">
      ${["board","booking","catalog","reports","operations"].map(key=>`<button type="button" data-action="page" data-value="${key}" aria-pressed="${key === page}">${t(key)}</button>`).join("")}
    </nav>` : ""}
    <div class="workspace">
      ${(role === "doctor" || page === "board") ? appointmentBoard() + detail(appointment()) + (role === "admin" ? followupsDue() : "") : {booking,catalog,reports,operations}[page]()}
    </div>`;
}

function render(focus) {
  const html = document.documentElement;
  html.lang=lang;
  html.dir=lang === "ar" ? "rtl" : "ltr";
  document.querySelector("#skip").textContent=t("skip");
  app.innerHTML = `<header class="top"><div class="shell mast">
    <div class="brand"><span class="mark" aria-hidden="true"></span><bdi>ClinicOS</bdi></div>
    <div class="mast-actions">${role ? chip(role)+button("signOut") : ""}
      <button id="language" type="button" class="language" data-action="language" lang="${lang==="ar"?"en":"ar"}">${lang==="ar"?"English":"العربية"}</button>
    </div></div></header><main id="main" tabindex="-1" class="shell">
      <p id="working" class="left-note" hidden>${t("working")}</p>
      ${status ? `<p tabindex="-1" id="status" class="left-note${status.error ? " error" : ""}">${t(status.key)}</p>` : ""}
      ${role ? workspace() : `<div class="page-head">${login()}</div>`}
    </main>`;
  if (focus) document.querySelector(focus)?.focus();
}

function formValues() {
  return [...app.querySelectorAll("form[data-form]")].map(form => [
    form.dataset.form,
    [...form.elements].filter(field => field.name && !["file","password"].includes(field.type))
      .map(field => [field.name,field.value,field.checked]),
  ]);
}

function restoreForms(values) {
  for (const [key,fields] of values) {
    const form = app.querySelector(`form[data-form="${key}"]`);
    for (const [name,value,checked] of fields) {
      const field = form?.elements.namedItem(name);
      if (!field) continue;
      if (field.type === "checkbox") field.checked = checked;
      else field.value = value;
    }
  }
}

function confirmation(key, text, filename) {
  dialog.innerHTML = `<h2 id="confirm-title">${t(key)}</h2><p id="confirm-info">${text}${filename ? `<br><strong>${safeName(filename)}</strong>` : ""}</p>
    <form method="dialog" class="actions"><button value="cancel" autofocus>${t("cancel")}</button>
    <button class="primary" value="yes">${t("confirm")}</button></form>`;
  dialog.setAttribute("aria-labelledby","confirm-title");
  dialog.setAttribute("aria-describedby","confirm-info");
  dialog.returnValue="";
  dialog.showModal();
  return new Promise(resolve=>{resolveConfirm=resolve;});
}
dialog.addEventListener("close",()=>resolveConfirm?.(dialog.returnValue === "yes"));

function printApprovedSummary(a) {
  if (!a || chart?.summary?.state !== "approved") return;
  const sheet = document.querySelector("#print-summary");
  sheet.innerHTML = `<h1>${t("summary")}</h1>
    <p>${safeName(a.patient)} · ${safeName(calendarDate(date))}</p><p>${esc(chart.summary.text)}</p>`;
  window.addEventListener("afterprint",()=>sheet.replaceChildren(),{once:true});
  window.print();
}

async function changeAndRefresh(key, data) {
  await fetchApi(key,data);
  await loadBoard();
  message("done");
}
async function fileOperation(action, id) {
  const a = appointment();
  const f = chart?.files.find(f=>f.id===id);
  if (!a || !f) return;
  if (action === "send") {
    if (!await confirmation("send",`${t("confirmSend")} ${safeName(a.patient)}`,f.name)) return;
    return perform(async()=>{
      try {
        await fetchApi("send",{visit_id:a.visit_id,attachment_id:id});
        message("sent");
      } finally {
        await loadChart();
      }
    });
  }
  return perform(async()=>{
    const file = await fetchApi("download",{attachment_id:id},true);
    const link = document.createElement("a");
    link.href=URL.createObjectURL(file);
    link.download=f.name;
    link.click();
    setTimeout(()=>URL.revokeObjectURL(link.href),1000);
  });
}

function requestId(key, data) {
  const fingerprint = key + JSON.stringify(data);
  if (!requestIds.has(fingerprint)) requestIds.set(fingerprint,crypto.randomUUID());
  return {fingerprint,id:requestIds.get(fingerprint)};
}
async function writeOnce(key,data) {
  const {fingerprint,id}=requestId(key,data);
  await fetchApi(key,{...data,request_id:id});
  await loadBoard();
  requestIds.delete(fingerprint);
  message("done");
}

const forms = {
  async login(data) {
    role=(await fetchApi("login",data)).role;
    page="board";
    await loadBoard();
  },
  async date(data) { date=data.date; report=null; slots=followupSlots=null; await loadBoard(); },
  async availability(data) {
    const r=await fetchApi("availability",{action:"availability",doctor_id:data.doctor,date:data.date});
    slots={doctor:data.doctor,date:data.date,items:r.available_slots ?? []};
  },
  book(data) {
    const slot=slots?.items[Number(data.slot)];
    if (!slot || !data.patient) throw new Error("VALIDATION_ERROR");
    return changeAndRefresh("availability",{action:"book",doctor_id:slots.doctor,patient_id:data.patient,
      date:slots.date,start_time:time(slot.start_time),end_time:time(slot.end_time)}).then(()=>{slots=null;});
  },
  reschedule(data,a) {
    return changeAndRefresh("booking-change",{p_appointment:a.id,p_action:"reschedule",p_date:data.date,p_start:data.start,p_end:data.end});
  },
  payment(data,a) { return writeOnce("payment",{invoice_id:a.invoice.id,...data}); },
  catalog(data) { return writeOnce("catalog",{...data,active:data.active==="on",action:catalogCode ? "update" : "create"}); },
  notes(data,a) { return changeAndRefresh(a.finalized ? "amend" : "save-notes",{visit_id:a.visit_id,content:{...noteData(),notes:data.notes}}); },
  async upload(data,a) {
    const file=data.file;
    if (!file?.size || file.size>5*1024*1024 || !/\.(pdf|png|jpe?g)$/i.test(file.name)) throw new Error("FILE_TYPE");
    const multipart=new FormData();
    multipart.append("visit_id",a.visit_id);
    multipart.append("file",file);
    await fetchApi("upload",multipart);
    await loadChart();
    message("done");
  },
  async "followup-slots"(data,a) {
    clearFollowupSlots();
    const result=await fetchApi("follow-up",{action:"slots",visit_id:a.visit_id,date:data.date});
    followupSlots={visitId:a.visit_id,date:result.date,items:result.available_slots};
  },
  async followup(data,a) {
    const available=followupSlots;
    const selectedSlot=available?.items[Number(data.slot)];
    if (!data.slot || available?.visitId!==a.visit_id || !selectedSlot) throw new Error("VALIDATION_ERROR");
    try {
      await fetchApi("follow-up",{action:"book",visit_id:a.visit_id,date:available.date,
        start_time:selectedSlot.start_time,end_time:selectedSlot.end_time});
    } catch (error) {
      if (error.message==="FOLLOWUP_SLOT_UNAVAILABLE") clearFollowupSlots();
      throw error;
    }
    followupSlots=null;
    await loadBoard();
    message("followupSaved");
  },
  async "summary-review"(data,a) { await reviewSummary(a,"edit",data.text); },
  finalize(data,a) {
    const services=Object.entries(data).filter(([,v])=>Number(v)>0).map(([service_code,quantity])=>({service_code,quantity:Number(quantity)}));
    if (!services.length) { message("addServices",true); return; }
    return changeAndRefresh("finalize",{visit_id:a.visit_id,services});
  },
};

async function reviewSummary(a,action,text = null) {
  await fetchApi("review-summary",{visit_id:a.visit_id,draft_id:chart.summary.id,action,text});
  await loadChart();
  message("done");
}

app.addEventListener("submit",async event=>{
  event.preventDefault();
  if (busy) return;
  const key=event.target.dataset.form;
  const data=Object.fromEntries(new FormData(event.target));
  const a=appointment();
  if (key==="payment" && !await confirmation("pay",`${t("confirmPayment")} ${safeName(a.patient)} · ${safeName(currency(data.amount))}`)) return;
  if (key==="finalize" && !await confirmation("finalize",`${t("confirmVisit")} ${safeName(a.patient)}`)) return;
  if (forms[key]) await perform(()=>forms[key](data,a));
});

app.addEventListener("change",event=>{
  if (event.target.matches('form[data-form="followup-slots"] input[name="date"]')) {
    clearFollowupSlots();
  }
  if (event.target.id === "service-picker" && !busy) {
    catalogCode=event.target.value;
    render("#service-picker");
  }
});

app.addEventListener("click",async event=>{
  const control=event.target.closest("[data-action]");
  if (!control || busy) return;
  const {action,value}=control.dataset;
  const a=appointment();
  if (action==="language") {
    const values=formValues();
    lang=lang==="ar"?"en":"ar";
    localStorage.setItem("clinicos-language",lang);
    render("#language");
    restoreForms(values);
    return;
  }
  if (action==="page") {page=value;status=null;render();return;}
  if (action==="choose") {
    selected=value; chart=followupSlots=null;
    await perform(loadChart);
    document.querySelector("#patient")?.focus();
    return;
  }
  if (action==="download" || action==="send") return fileOperation(action,value);
  if (action==="printSummary") return printApprovedSummary(a);
  if (action==="cancelBooking" && !await confirmation(action,`${t("confirmCancel")} ${safeName(a.patient)}`)) return;
  const task = {
    signOut:async()=>{await fetchApi("logout"); role=board=chart=selected=date=slots=followupSlots=report=handoffs=catalogCode=null;requestIds.clear();},
    checkIn:()=>changeAndRefresh("check-in",{appointment_id:a.id}),
    cancelBooking:()=>changeAndRefresh("booking-change",{p_appointment:a.id,p_action:"cancel",p_date:null,p_start:null,p_end:null}),
    start:()=>changeAndRefresh("start-visit",{visit_id:a.visit_id}),
    generate:async()=>{
      try { await fetchApi("summary",{visit_id:a.visit_id}); }
      catch (error) {
        if (error.message === "UPSTREAM_UNAVAILABLE") throw new Error("SUMMARY_UNAVAILABLE");
        throw error;
      }
      await loadChart();
      message("done");
    },
    approve:()=>reviewSummary(a,"approve"),
    reject:()=>reviewSummary(a,"reject"),
    loadReport:async()=>{report=await fetchApi("daily-report",{date});},
    loadOperations:async()=>{handoffs=await fetchApi("operations",{action:"list"});},
    assign:async()=>{await fetchApi("operations",{action,handoff_id:value});handoffs=await fetchApi("operations",{action:"list"});},
    resolve:async()=>{await fetchApi("operations",{action,handoff_id:value});handoffs=await fetchApi("operations",{action:"list"});},
  }[action];
  if (task) await perform(task);
});

render();
fetch("/api/session")
  .then(response=>response.json())
  .then(async session=>{
    role=session.role;
    if (role) await perform(loadBoard);
  })
  .catch(()=>{message("upstream",true);render();});
