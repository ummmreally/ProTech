# Attendance System Guide

## Overview
The **Attendance** system replaces the old "Time Clock" and removes the unused "Time" (billable time tracking) feature. This comprehensive system is designed for employee attendance tracking, payroll management, and time card administration.

## Features

### 1. PIN-Based Clock In/Out (Left Panel)
- **Quick Access**: Employees can clock in/out using their 4-6 digit PIN
- **No Login Required**: Direct access from the attendance screen
- **Visual Feedback**: Large number pad with visual PIN indicators
- **Real-Time Display**: 
  - Current time and date
  - Employee name when clocked in
  - Active shift duration
  - Break status
- **Quick Actions**:
  - Start/End Break
  - Clock Out

### 2. Time Card Management (Right Panel)

#### Edit Time Cards
- **Admin Control**: Review and edit employee time entries
- **Filters**:
  - Select specific employee or view all
  - Date ranges: Today, This Week, Last Week, This Month, Custom
- **Audit Trail**: Every edit is tracked with:
  - Who made the edit
  - When it was edited
  - Reason for the edit (required)
- **Visual Indicators**: Edited entries are clearly marked
- **Edit Capabilities**:
  - Adjust clock in/out times
  - Add admin notes
  - View edit history

#### Time Off Requests
- Placeholder for future implementation
- Will allow employees to request PTO, sick days, etc.
- Admin approval workflow

#### Attendance Reports
- Placeholder for future implementation
- Will provide analytics and reporting on attendance patterns

## Setting Up Employee PINs

Employees need a PIN code to use the clock-in system:

1. Go to **Employees** tab
2. Select an employee
3. Edit their profile
4. Set a 4-6 digit PIN code
5. Employees can now use this PIN to clock in/out

## How Employees Use It

1. Navigate to **Attendance** tab
2. Enter your PIN using the number pad
3. Press checkmark or wait for auto-submit (after 4 or 6 digits)
4. System confirms clock in and displays:
   - Your name
   - Current shift duration
   - Quick action buttons

### Taking a Break
1. When clocked in, press **"Start Break"**
2. Break time is tracked separately
3. Press **"End Break"** to resume work

### Clocking Out
1. Press **"Clock Out"** button
2. System calculates total hours (minus break time)
3. Entry is saved for payroll

## Admin Functions

### Editing Time Cards
Admins can correct mistakes or adjust entries:

1. Switch to **"Edit Time Cards"** tab
2. Select employee and date range
3. Click the edit button on any entry
4. Adjust clock in/out times
5. **Must provide a reason** for the edit
6. Save changes

All edits are logged with:
- Admin name
- Timestamp
- Reason provided

### Viewing Attendance
- Filter by employee to see individual attendance
- Filter by date range for payroll periods
- See active shifts vs completed shifts
- Track break time per shift

## Data Tracked

For each time clock entry:
- **Clock In Time**: When shift started
- **Clock Out Time**: When shift ended (if completed)
- **Break Duration**: Total break time during shift
- **Total Hours**: Working hours (excludes breaks)
- **Status**: Active, On Break, or Completed
- **Edit History**: If modified by admin
- **Notes**: Employee or admin notes

## Integration with Payroll

The attendance system tracks:
- Daily hours per employee
- Weekly/monthly totals
- Hourly rate (set in employee profile)
- Calculated pay based on hours × rate

This data can be exported for payroll processing.

## Removed Features

The following features were removed as they were unused:

- **Time/Time Tracking Tab**: This was for tracking billable hours on tickets
- **Billable Time Entries**: Tracked time per ticket for customer billing
- **Revenue Tracking**: Calculated billable amounts

These features are different from employee attendance and were causing confusion.

## ✅ Implemented Features

### 1. Time Off Management System

**Employee Requests:**
- Request time off with date range selection
- Multiple request types: PTO, Sick Leave, Vacation, Personal Day, Bereavement, Unpaid Leave
- Automatic business days calculation (excludes weekends)
- Optional reason field
- Real-time status tracking

**Admin Approval Workflow:**
- Review all pending requests
- Approve or deny with admin notes
- Complete audit trail of who approved/denied
- Filter requests by status (All, Pending, Approved, Denied)
- Visual status indicators with color coding

**Request Types Available:**
- 🗓️ **PTO** - Paid Time Off
- 🏥 **Sick Leave** - Medical absences
- 🏖️ **Vacation** - Planned vacations
- 👤 **Personal Day** - Personal matters
- ❤️ **Bereavement** - Family emergencies
- 📅 **Unpaid Leave** - Unpaid absences

### 2. Attendance Reports & Analytics

**Dashboard Metrics:**
- **Total Hours** - Aggregate hours worked for selected period
- **Late Arrivals** - Count of employees arriving late (>5 min grace period)
- **Overtime Hours** - Total overtime based on scheduled hours
- **Attendance Rate** - Overall attendance percentage

**Filtering Options:**
- Today, This Week, Last Week, This Month, Last Month
- Filter by specific employee or view all
- Real-time calculations

**Employee Analytics:**
- Hours worked per employee
- Late arrival count per employee  
- Overtime hours per employee
- Side-by-side comparison view

### 3. Late Arrival Tracking

**How It Works:**
- Compares actual clock-in time against scheduled start time
- 5-minute grace period before marking as late
- Requires employee schedule to be set up
- Automatically tracked in reports
- Visual indicators in orange for late arrivals

**Requirements:**
- Employee must have a schedule configured
- Schedule defines expected start time per day of week
- System compares clock-in time to scheduled time

### 4. Overtime Calculation

**Automatic Tracking:**
- Compares actual hours worked vs scheduled hours
- Calculates overtime per shift
- Aggregates overtime for reporting periods
- Displayed in purple for visibility

**How It's Calculated:**
- Scheduled Hours (from EmployeeSchedule) = Expected hours per day
- Actual Hours = Clock out - Clock in - Break time
- Overtime = Actual Hours - Scheduled Hours (if positive)

**Reports Show:**
- Total overtime hours across all employees
- Overtime per employee breakdown
- Helps identify workload issues

### 5. Schedule Integration

**Employee Schedules:**
- Set expected work hours per day of week
- Define start and end times for each day
- Used for late arrival detection
- Used for overtime calculations
- Track scheduled vs actual hours

**Schedule Model:**
- Day of week (Monday-Sunday)
- Scheduled start time
- Scheduled end time  
- Active/inactive status
- Automatically calculates scheduled hours

## Future Enhancements

Additional features planned:

1. **PTO Balance Tracking**:
   - Accrual rates
   - Used vs available days
   - Carryover rules
   - Balance alerts

2. **Advanced Reports**:
   - Export to CSV/PDF
   - Custom date ranges
   - Trend analysis
   - Performance insights

3. **Notifications**:
   - Remind employees to clock out
   - Alert admins of unusual patterns
   - Shift reminders
   - Time off request alerts

4. **Schedule Management**:
   - Bulk schedule creation
   - Template schedules
   - Shift swapping
   - Schedule conflict detection

## Security

- PINs are stored securely
- Only active employees can clock in
- Edit permissions restricted to admins
- Complete audit trail of all changes
- No ability to delete historical entries (only edit with tracking)

## Best Practices

1. **Set unique PINs** for each employee
2. **Review time cards weekly** before processing payroll
3. **Document all edits** with clear reasons
4. **Regular audits** of attendance patterns
5. **Train employees** on proper clock in/out procedures
