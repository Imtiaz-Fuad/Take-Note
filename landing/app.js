/* Take-Note landing page — mirrors lib/services/bdapps_service.dart */
(function () {
  'use strict';

  // Same base URL as the Flutter app
  const BASE_URL = 'https://www.bdappsdigitalapps.com/NADB26088';

  // Mirrors the Dart BdappsService endpoints
  const endpoints = {
    sendOtp:        `${BASE_URL}/send_otp.php`,
    verifyOtp:      `${BASE_URL}/verify_otp.php`,
    check:          `${BASE_URL}/check_subscription.php`,
    unsubscribe:    `${BASE_URL}/unsubscribe.php`,
  };

  const TIMEOUT_MS = 20000;

  /** POST form-encoded data and parse the JSON response. */
  async function postForm(url, fields) {
    const body = new URLSearchParams(fields).toString();
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body,
        signal: controller.signal,
        mode: 'cors',
      });
      const text = await res.text();
      try {
        const data = JSON.parse(text);
        return data && typeof data === 'object' ? data : { error: 'Unexpected response shape' };
      } catch (e) {
        return { error: 'Invalid JSON from server', raw: text };
      }
    } catch (e) {
      return { error: `Network error: ${e.message || e}` };
    } finally {
      clearTimeout(timer);
    }
  }

  const api = {
    sendOtp:        (mobile)        => postForm(endpoints.sendOtp,     { user_mobile: mobile }),
    verifyOtp:      (otp, refNo)    => postForm(endpoints.verifyOtp,   { Otp: otp, referenceNo: refNo }),
    checkSub:       (mobile)        => postForm(endpoints.check,       { user_mobile: mobile }),
    unsubscribe:    (mobile)        => postForm(endpoints.unsubscribe, { user_mobile: mobile }),
  };

  // ---------- DOM helpers ----------
  const $ = (id) => document.getElementById(id);
  const els = {
    stepper:        $('stepper'),
    stepMobile:     $('step-mobile'),
    stepOtp:        $('step-otp'),
    stepDone:       $('step-done'),
    mobile:         $('mobile'),
    otp:            $('otp'),
    btnSendOtp:     $('btn-send-otp'),
    btnCheck:       $('btn-check-status'),
    btnVerify:      $('btn-verify'),
    btnResend:      $('btn-resend'),
    btnUnsubscribe: $('btn-unsubscribe'),
    btnChangeNo:    $('btn-change-number'),
    statusMobile:   $('status-mobile'),
    statusOtp:      $('status-otp'),
    resultBox:      $('result-box'),
    resultIcon:     $('result-icon'),
    resultTitle:    $('result-title'),
    resultMessage:  $('result-message'),
    year:           $('year'),
  };

  // State (mirrors Flutter's _SubscriptionScreenState)
  const state = {
    step: 'mobile',          // mobile | otp | done
    referenceNo: null,
    // Remember the mobile we last subscribed / checked, so the Unsubscribe
    // button on the 'done' step can call unsubscribe.php directly.
    lastMobile: '',
    loading: { send: false, check: false, verify: false, unsub: false },
  };

  function setLoading(which, on) {
    state.loading[which] = on;
    const map = {
      send:   els.btnSendOtp,
      check:  els.btnCheck,
      verify: els.btnVerify,
      unsub:  els.btnUnsubscribe,
    };
    const btn = map[which];
    if (!btn) return;
    btn.disabled = on;
    const spinner = btn.querySelector('.spinner');
    const label   = btn.querySelector('.btn-label');
    if (spinner) spinner.hidden = !on;
    if (label)   label.style.opacity = on ? '0.7' : '1';
  }

  function showStatus(node, kind, text) {
    node.classList.remove('is-info', 'is-success', 'is-error');
    if (text) node.classList.add(`is-${kind}`);
    node.textContent = text || '';
  }

  function showStep(step) {
    state.step = step;
    els.stepMobile.hidden = step !== 'mobile';
    els.stepOtp.hidden    = step !== 'otp';
    els.stepDone.hidden   = step !== 'done';

    // Stepper visuals
    const pills = els.stepper.querySelectorAll('.step-pill');
    pills.forEach((p) => p.classList.remove('is-active', 'is-done'));
    const order = ['mobile', 'otp', 'done'];
    const idx = order.indexOf(step);
    pills.forEach((p, i) => {
      if (i < idx) p.classList.add('is-done');
      else if (i === idx) p.classList.add('is-active');
    });
  }

  function validateMobile(m) {
    return /^01[3-9]\d{8}$/.test(m);
  }

  // ---------- Action handlers ----------

  async function onSendOtp() {
    const mobile = els.mobile.value.trim();
    showStatus(els.statusMobile, 'info', '');
    if (!validateMobile(mobile)) {
      showStatus(els.statusMobile, 'error', 'Enter a valid BD mobile number (e.g. 01XXXXXXXXX).');
      els.mobile.focus();
      return;
    }

    setLoading('send', true);
    try {
      const r = await api.sendOtp(mobile);
      if (r.error) {
        showStatus(els.statusMobile, 'error', r.error);
        return;
      }
      if (r.success === true && r.referenceNo) {
        state.referenceNo = String(r.referenceNo);
        state.lastMobile = mobile;
        showStatus(els.statusOtp, 'info', 'OTP sent. Enter the code below.');
        showStep('otp');
        setTimeout(() => els.otp.focus(), 50);
      } else {
        showStatus(
          els.statusMobile,
          'error',
          r.message || r.statusDetail || 'Failed to send OTP.'
        );
      }
    } finally {
      setLoading('send', false);
    }
  }

  async function onVerifyOtp() {
    const otp = els.otp.value.trim();
    showStatus(els.statusOtp, 'info', '');
    if (!otp) {
      showStatus(els.statusOtp, 'error', 'Enter the OTP you received.');
      els.otp.focus();
      return;
    }
    if (!state.referenceNo) {
      showStatus(els.statusOtp, 'error', 'Session expired. Please request a new OTP.');
      showStep('mobile');
      return;
    }

    setLoading('verify', true);
    try {
      const r = await api.verifyOtp(otp, state.referenceNo);
      const code = (r.statusCode || '').toString().toUpperCase();
      if (code === 'S1000' || code === 'SUCCESS' || r.success === true) {
        showResult({
          success: true,
          title: 'Subscription confirmed',
          message: "You're all set. Thank you for subscribing to Take-Note.",
        });
        showStep('done');
      } else {
        showStatus(
          els.statusOtp,
          'error',
          r.statusDetail || r.message || r.error || 'OTP verification failed.'
        );
      }
    } finally {
      setLoading('verify', false);
    }
  }

  async function onCheckStatus() {
    const mobile = els.mobile.value.trim();
    showStatus(els.statusMobile, 'info', '');
    if (!validateMobile(mobile)) {
      showStatus(els.statusMobile, 'error', 'Enter a valid BD mobile number (e.g. 01XXXXXXXXX).');
      els.mobile.focus();
      return;
    }

    setLoading('check', true);
    try {
      const r = await api.checkSub(mobile);
      if (r.error) {
        showStatus(els.statusMobile, 'error', r.error);
        return;
      }
      if (r.isSubscribed === true) {
        state.lastMobile = mobile;
        showResult({
          success: true,
          title: 'You are subscribed',
          message: 'This number already has an active subscription.',
        });
        showStep('done');
      } else {
        showStatus(els.statusMobile, 'info', 'Not subscribed yet. Tap "Subscribe — Send OTP" to start.');
      }
    } finally {
      setLoading('check', false);
    }
  }

  async function onUnsubscribe() {
    // Prefer the mobile we last subscribed / verified; fall back to the input
    // so the user can still unsubscribe from the mobile step if needed.
    const mobile = (state.lastMobile || els.mobile.value || '').trim();
    if (!validateMobile(mobile)) {
      showResult({
        success: false,
        title: 'Number required',
        message: 'Please re-enter your mobile number to unsubscribe.',
      });
      showStep('mobile');
      return;
    }

    // Mirror the Flutter AlertDialog — one tap to confirm, then unsubscribe.
    const ok = window.confirm(
      `Unsubscribe ${mobile} from Take-Note updates?\n\nYou can resubscribe anytime.`
    );
    if (!ok) return;

    setLoading('unsub', true);
    try {
      const r = await api.unsubscribe(mobile);
      const code = (r.statusCode || '').toString().toUpperCase();
      const okResp = r.success === true || code === 'S1000' || code === 'SUCCESS';
      if (okResp) {
        state.referenceNo = null;
        state.lastMobile = '';
        els.otp.value = '';
        showResult({
          success: true,
          title: 'Unsubscribed',
          message: 'You have been unsubscribed successfully.',
        });
        showStep('mobile');
        showStatus(els.statusMobile, 'success', 'Unsubscribed successfully.');
      } else {
        showStatus(
          els.statusMobile,
          'error',
          r.statusDetail || r.message || r.error || 'Unsubscribe failed.'
        );
      }
    } finally {
      setLoading('unsub', false);
    }
  }

  function onChangeNumber() {
    state.referenceNo = null;
    els.otp.value = '';
    showStatus(els.statusMobile, 'info', '');
    showStatus(els.statusOtp, 'info', '');
    showStep('mobile');
    setTimeout(() => els.mobile.focus(), 50);
  }

  function showResult({ success, title, message }) {
    els.resultIcon.classList.toggle('is-error', !success);
    els.resultIcon.textContent = success ? '✓' : '!';
    els.resultTitle.textContent = title;
    els.resultMessage.textContent = message;
  }

  // ---------- Wire up ----------

  els.btnSendOtp.addEventListener('click', onSendOtp);
  els.btnCheck.addEventListener('click', onCheckStatus);
  els.btnVerify.addEventListener('click', onVerifyOtp);
  els.btnResend.addEventListener('click', onSendOtp);
  els.btnUnsubscribe.addEventListener('click', onUnsubscribe);
  els.btnChangeNo.addEventListener('click', onChangeNumber);

  // Allow Enter key to advance forms
  els.mobile.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') { e.preventDefault(); onSendOtp(); }
  });
  els.otp.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') { e.preventDefault(); onVerifyOtp(); }
  });

  // Footer year
  if (els.year) els.year.textContent = String(new Date().getFullYear());

  // Initial render
  showStep('mobile');
})();
