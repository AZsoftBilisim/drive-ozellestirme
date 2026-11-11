
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Sets transactional locks on the record of the information register Lockingoperation_2_2,
//	in the context of a given division.
//
// Parameters:
//  Department - CatalogRef.BusinessStructure - the division
//		that you want to set a blocker for.
//  Mode - DataLockMode - lockable mode.
//
Procedure BlockDivision(Department, Mode) Export
	
	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.BlockingOperationalSchedule2_2");
	LockItem.Mode = Mode;
	
	If ValueIsFilled(Department) Then
		LockItem.SetValue("Department", Department);
	EndIf;
	
	Block.Lock();
	
EndProcedure

// Sets transactional locks on the record of the information register Lockingoperation_2_2,
//	in the context of a given collection of divisions.
//
// Parameters:
//  Collection - QueryResult, TabularSection, ValueTable - a collection
//		containing divisions to block. Must contain the "Division" field
//		containing the values to block.
//  CollectionField - String - name of the collection field containing divisions.
//  Mode - DataLockMode - lockable mode.
//
Procedure BlockCollection(Collection, CollectionField, Mode) Export
	
	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.BlockingOperationalSchedule2_2");
	LockItem.Mode = Mode;
	
	If ValueIsFilled(Collection) Then
		LockItem.DataSource = Collection;
		LockItem.UseFromDataSource("Department", CollectionField);
	EndIf;
	
	Block.Lock();
	
EndProcedure

// Records data about blocking the division's schedule.
//	Type of lock to set: Unit.
//
// Parameters:
//  Department - CatalogRef.BusinessStructure - the Department whose schedule you want to block.
//
Procedure ChangedControlMethod(Department) Export
	
	LockReason = Enums.ReasonsForOperationTimetableLocks.ManagementMethodIsChanged;
	
	Set = InformationRegisters.BlockingOperationalSchedule2_2.CreateRecordSet();
	Set.Filter.Department.Set(Department);
	Set.Filter.LockReason.Set(LockReason);
	
	Record = Set.Add();
	Record.Department = Department;
	Record.LockReason = LockReason;
	Record.User = Users.CurrentUser();
	
	Set.Write();
	
EndProcedure

// Deletes data about blocking the division's schedule.
//
// Parameters:
//  Department - CatalogRef.BusinessStructure - the division whose schedule needs to be unblocked.
//
Procedure UnlockChangedControlMethod(Department) Export
	
	Set = InformationRegisters.BlockingOperationalSchedule2_2.CreateRecordSet();
	Set.Filter.Department.Set(Department);
	Set.Filter.LockReason.Set(Enums.ReasonsForOperationTimetableLocks.ManagementMethodIsChanged);
	Set.Write();
	
EndProcedure

// Writes data about schedule operations that are being blocked to the Block_operation_2_2 information register.
//	Type of lock to set: Operation.
//
// Parameters:
//  SessionNumber	- Number - session number of the user who sets the schedule lock.
//  SessionStarted - Date - the start date (and time) of the session of the user who sets the schedule lock.
//  Department - CatalogRef.BusinessStructure - the division that the blocked operations belong to.
//  User - CatalogRef.Users - the user who sets the lock.
//  Operations - Array - contains the structure of the interlocked operations.
//
Procedure BlockScheduleCalculation(SessionNumber, SessionStarted, Department, User, Operations) Export
	
	LockReason = Enums.ReasonsForOperationTimetableLocks.CalculateTimetable;
	
	Set = InformationRegisters.BlockingOperationalSchedule2_2.CreateRecordSet();
	Set.Filter.SessionNumber.Set(SessionNumber);
	Set.Filter.SessionStarted.Set(SessionStarted);
	Set.Filter.Department.Set(Department);
	Set.Filter.LockReason.Set(LockReason);
	
	For Each Operation In Operations Do
		
		Record = Set.Add();
		Record.SessionNumber = SessionNumber;
		Record.SessionStarted = SessionStarted;
		Record.Department = Department;
		Record.Stage = Operation.Stage;
		Record.Operation = Operation.Operation;
		Record.OperationID = Operation.OperationID;
		Record.LockReason = LockReason;
		Record.User = User;
		
	EndDo;
	
	Set.Write();
	
EndProcedure

// Deletes records about blocking operations set by the specified user.
//
// Parameters:
//  SessionNumber	- Number - the session number of the user whose lock should be removed.
//  SessionStarted - Date - date (and time) of the start of the user's session to remove the lock.
//  Department - CatalogRef.BusinessStructure - the division that the unlockable operations belong to.
//
Procedure UnblockScheduleCalculation(SessionNumber, SessionStarted, Department=Undefined) Export
	
	Set = InformationRegisters.BlockingOperationalSchedule2_2.CreateRecordSet();
	
	Set.Filter.SessionNumber.Set(SessionNumber);
	Set.Filter.SessionStarted.Set(SessionStarted);
	Set.Filter.LockReason.Set(Enums.ReasonsForOperationTimetableLocks.CalculateTimetable);
	
	If ValueIsFilled(Department) Then
		Set.Filter.Department.Set(Department);
	EndIf;
	
	Set.Write();
	
EndProcedure

// Returns a flag for whether there are actual operation locks for the specified division.
//
// Parameters:
//  Department - CatalogRef.BusinessStructure - the Department whose operations need to be checked.
//	LockReason - EnumRef.ReasonsForOperationTimetableLocks - the type of lock
//		to check for.
//
// Returns:
//  Boolean - the flag for the presence of locks.
//
Function DivisionScheduleBlocked(Department, LockReason=Undefined) Export
	
	Return TimetableIsBeingCalculated(Department,, LockReason);
	
EndFunction

// Returns a flag for whether there are actual locks for the specified set of operations.
//
// Parameters:
//  Operations - Array - array of operation identifiers.
//
// Returns:
//  Boolean - the flag for the presence of locks.
//
Function OperationsBlocked(Operations) Export
	
	LockReason = Enums.ReasonsForOperationTimetableLocks.CalculateTimetable;
	Return TimetableIsBeingCalculated(, Operations, LockReason);
	
EndFunction

// Returns the user who set the lock for the specified division.
//
// Parameters:
//  Department - CatalogRef.BusinessStructure - the division whose lock author you want to get.
//
// Returns:
//  CatalogRef.Users - the author of the lock.
//
Function DivisionScheduleAuthorBlocking(Department) Export
	
	Locks = InstalledLocks(Department);
	If ValueIsFilled(Locks) Then
		Return Locks[0].User;
	Else
		Return Catalogs.Users.EmptyRef();
	EndIf;
	
EndFunction

#EndRegion

#Region Private

Function TimetableIsBeingCalculated(Department = Undefined, Operations = Undefined, LockReason = Undefined)
	
	Locks = InstalledLocks(Department, Operations, LockReason);
	
	If ValueIsFilled(Locks) Then
		
		Result = False;
		For Each Block In Locks Do
			
			If Block.LockReason = Enums.ReasonsForOperationTimetableLocks.ManagementMethodIsChanged Then
				Result = True;
			Else
				
				Relevant_ = SessionLockingIsRelevant(Block.SessionNumber, Block.SessionStarted);
				If Relevant_ Then
					Result = True;
				Else
					RemoveSessionLock(Block.SessionNumber, Block.SessionStarted);
				EndIf;
			EndIf;
		
		EndDo;
		
	Else
		Result = False;
	EndIf;
	
	Return Result;
	
EndFunction

Function InstalledLocks(Department = Undefined, Operations = Undefined, LockReason = Undefined)
	
	Query = New Query(
	"SELECT DISTINCT
	|	BlockingOperationalSchedule.SessionNumber AS SessionNumber,
	|	BlockingOperationalSchedule.SessionStarted AS SessionStarted,
	|	BlockingOperationalSchedule.LockReason AS LockReason,
	|	BlockingOperationalSchedule.User AS User
	|FROM
	|	InformationRegister.BlockingOperationalSchedule2_2 AS BlockingOperationalSchedule
	|WHERE
	|	(NOT &FilterDepartment
	|			OR BlockingOperationalSchedule.Department = &Department)
	|	AND (NOT &FilterOperations
	|			OR BlockingOperationalSchedule.OperationID IN (&Operations))
	|	AND (NOT &FilterLockReason
	|			OR BlockingOperationalSchedule.LockReason = &LockReason)");
	
	Query.SetParameter("FilterDepartment", ValueIsFilled(Department));
	Query.SetParameter("Department", Department);
	
	Query.SetParameter("FilterOperations", ValueIsFilled(Operations));
	Query.SetParameter("Operations", ?(ValueIsFilled(Operations), Operations, New Array));
	
	Query.SetParameter("FilterLockReason", ValueIsFilled(LockReason));
	Query.SetParameter("LockReason", LockReason);
	
	Return Query.Execute().Unload();
	
EndFunction

Function SessionLockingIsRelevant(SessionNumber, SessionStarted)
	
	Relevant_ = False;
	
	SetPrivilegedMode(True);
	Session = GetCurrentInfoBaseSession();
	SetPrivilegedMode(False);
	
	If Session.SessionStarted = SessionStarted Then
		Relevant_ = True;
	EndIf;
	
	Return Relevant_;
	
EndFunction

Procedure RemoveSessionLock(SessionNumber, SessionStarted)
	
	Set = InformationRegisters.BlockingOperationalSchedule2_2.CreateRecordSet();
	Set.Filter.SessionNumber.Set(SessionNumber);
	Set.Filter.SessionStarted.Set(SessionStarted);
	Set.Write();
	
EndProcedure

#EndRegion

#EndIf