const PDFDocument = require('pdfkit');

/**
 * Generates a PDF report of leads and employee performance.
 * Pipes directly to the response stream.
 */
const generateReport = (res, data) => {
  const doc = new PDFDocument({ margin: 50, size: 'A4' });

  // Set response headers
  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', 'attachment; filename=dayaar_crm_report.pdf');

  doc.pipe(res);

  // ============ HEADER ============
  doc.fontSize(24).fillColor('#1A73E8').text('DAYAAR REAL ESTATE', { align: 'center' });
  doc.fontSize(12).fillColor('#666').text('CRM Lead Report', { align: 'center' });
  doc.moveDown(0.5);
  doc.fontSize(10).fillColor('#999').text(`Generated: ${new Date().toLocaleDateString('en-IN', { dateStyle: 'long' })}`, { align: 'center' });
  doc.moveDown(1);

  // ============ SUMMARY ============
  doc.fontSize(16).fillColor('#333').text('Summary', { underline: true });
  doc.moveDown(0.5);

  const summary = data.summary;
  doc.fontSize(11).fillColor('#444');
  doc.text(`Total Leads: ${summary.total}`);
  doc.text(`Hot Leads (Accepted): ${summary.accepted}`, { continued: false });
  doc.text(`Cold Leads (Rejected): ${summary.rejected}`);
  doc.text(`Pending: ${summary.pending}`);
  doc.text(`Total Employees: ${summary.employeeCount}`);
  doc.moveDown(1);

  // ============ EMPLOYEE PERFORMANCE ============
  doc.fontSize(16).fillColor('#333').text('Employee Performance', { underline: true });
  doc.moveDown(0.5);

  // Table header
  const tableTop = doc.y;
  const col1 = 50;
  const col2 = 200;
  const col3 = 290;
  const col4 = 370;
  const col5 = 450;

  doc.fontSize(10).fillColor('#1A73E8');
  doc.text('Employee', col1, tableTop);
  doc.text('Assigned', col2, tableTop);
  doc.text('Accepted', col3, tableTop);
  doc.text('Rejected', col4, tableTop);
  doc.text('Pending', col5, tableTop);
  doc.moveDown(0.5);

  // Draw line
  doc.moveTo(50, doc.y).lineTo(530, doc.y).stroke('#ddd');
  doc.moveDown(0.3);

  // Table rows
  doc.fillColor('#444').fontSize(10);
  if (data.employeeStats && data.employeeStats.length > 0) {
    data.employeeStats.forEach((emp) => {
      const y = doc.y;
      if (y > 700) {
        doc.addPage();
      }
      doc.text(emp.name, col1, doc.y, { width: 140 });
      const rowY = doc.y - doc.currentLineHeight();
      doc.text(String(emp.assigned), col2, rowY);
      doc.text(String(emp.accepted), col3, rowY);
      doc.text(String(emp.rejected), col4, rowY);
      doc.text(String(emp.pending), col5, rowY);
      doc.moveDown(0.3);
    });
  }

  doc.moveDown(1);

  // ============ HOT LEADS DETAILS ============
  if (data.hotLeads && data.hotLeads.length > 0) {
    doc.addPage();
    doc.fontSize(16).fillColor('#FF6B35').text('Hot Leads Details', { underline: true });
    doc.moveDown(0.5);

    data.hotLeads.forEach((lead, idx) => {
      if (doc.y > 680) doc.addPage();
      doc.fontSize(11).fillColor('#333').text(`${idx + 1}. ${lead.name} - ${lead.phone}`);
      doc.fontSize(9).fillColor('#666');
      if (lead.report) {
        doc.text(`   Property Interest: ${lead.report.propertyInterest || 'N/A'}`);
        doc.text(`   Budget: ${lead.report.budgetRange || 'N/A'}`);
        doc.text(`   Location: ${lead.report.preferredLocation || 'N/A'}`);
        doc.text(`   BHK: ${lead.report.bhk || 'N/A'}`);
        doc.text(`   Desired Place: ${lead.report.desiredPlace || 'N/A'}`);
        doc.text(`   Follow-up: ${lead.report.followUpDate ? new Date(lead.report.followUpDate).toLocaleDateString('en-IN') : 'N/A'}`);
        doc.text(`   Notes: ${lead.report.notes || 'N/A'}`);
        doc.text(`   Extra Info: ${lead.report.extraInfo || 'N/A'}`);
        doc.text(`   Handled By: ${lead.report.employeeName || 'N/A'}`);
      }
      doc.moveDown(0.5);
    });
  }

  // ============ COLD LEADS DETAILS ============
  if (data.coldLeads && data.coldLeads.length > 0) {
    doc.addPage();
    doc.fontSize(16).fillColor('#42A5F5').text('Cold Leads Details', { underline: true });
    doc.moveDown(0.5);

    data.coldLeads.forEach((lead, idx) => {
      if (doc.y > 700) doc.addPage();
      doc.fontSize(11).fillColor('#333').text(`${idx + 1}. ${lead.name} - ${lead.phone}`);
      doc.fontSize(9).fillColor('#666');
      if (lead.report) {
        doc.text(`   Reason: ${lead.report.rejectionReason || 'N/A'}`);
        doc.text(`   Handled By: ${lead.report.employeeName || 'N/A'}`);
      }
      doc.moveDown(0.3);
    });
  }

  // ============ FOOTER ============
  doc.fontSize(8).fillColor('#aaa').text('Dayaar Real Estate Consultant - Confidential Report', 50, 750, { align: 'center' });

  doc.end();
};

module.exports = { generateReport };
