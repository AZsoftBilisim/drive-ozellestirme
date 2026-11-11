#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)

	InitializeDocument();

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	KeyAttributes = New Array;
	KeyAttributes.Add("PayCode");
	TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "StandardsByPayCodes", KeyAttributes, Cancel);
	
	DocumentsPayrollAndHumanResourcesServer.CheckCorrectnessOfMonthOfRegistration(ThisObject, Cancel);
	
	ListOfTypesOfTime = CheckDuplicatesOfNormsForCurrentMonth();
	For Each CurrentValue In ListOfTypesOfTime Do
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'По графику работ:%1 вид рабочего времени %2 уже был введен за месяц %3 другим документом. Повторный ввод запрещен.';
						|vi = 'For the ""%1"" work schedule, the ""%2""  work time type is already entered for %3 by another document. Cannot enter it again.';
						|en = 'For the ""%1"" work schedule, the ""%2""  work time type is already entered for %3 by another document. Cannot enter it again.'; fa = 'For the ""%1"" work schedule, the ""%2""  work time type is already entered for %3 by another document. Cannot enter it again.';
						|it = 'For the ""%1"" work schedule, the ""%2""  work time type is already entered for %3 by another document. Cannot enter it again.';
						|pl = 'For the ""%1"" work schedule, the ""%2""  work time type is already entered for %3 by another document. Cannot enter it again.';
						|tr = '%1 çalışma takviminde %2 çalışma zamanı türü %3 ayı için başka bir belgeyle zaten girilmiş. Tekrar giriş yapılamaz.'"),
						ScheduleOfWork, CurrentValue.PayCode, MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(RegistrationMonth));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			CommonClientServer.PathToTabularSection("StandardsByPayCodes", CurrentValue.LineNumber, "PayCode"),
			,
			Cancel);
		
	EndDo;	
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load  Then
		Return;
	EndIf;
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);	
	
	If WriteMode = DocumentWriteMode.UndoPosting
		And DocumentsPayrollAndHumanResourcesServer.DocumentIsUsedInCalculatingPOData(Ref) Then
		
		DocumentsPayrollAndHumanResourcesServer.ReportErrorsCancellationOfEvent(Ref, Cancel);	
	EndIf;	
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	RegistrationMonth = BegOfMonth(CurrentSessionDate());
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

Function CheckDuplicatesOfNormsForCurrentMonth()
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	StandardWorkingHoursStandardsByPayCodes.PayCode AS PayCode,
	|	StandardWorkingHoursStandardsByPayCodes.LineNumber AS LineNumber,
	|	StandardWorkingHours.ScheduleOfWork AS ScheduleOfWork
	|FROM
	|	Document.StandardWorkingHours.StandardsByPayCodes AS StandardWorkingHoursStandardsByPayCodes
	|		LEFT JOIN Document.StandardWorkingHours AS StandardWorkingHours
	|		ON StandardWorkingHoursStandardsByPayCodes.Ref = StandardWorkingHours.Ref
	|WHERE
	|	StandardWorkingHours.RegistrationMonth = &RegistrationMonth
	|	AND StandardWorkingHours.Posted
	|	AND StandardWorkingHoursStandardsByPayCodes.PayCode IN(&ListOfTypesOfWorkingHours)
	|	AND StandardWorkingHours.Ref <> &LinkOfCurrentDocument
	|	AND StandardWorkingHours.ScheduleOfWork = &ScheduleOfWork";
	
	Query.SetParameter("RegistrationMonth", RegistrationMonth);
	Query.SetParameter("ScheduleOfWork",      ScheduleOfWork);
	Query.SetParameter("ListOfTypesOfWorkingHours", 
		StandardsByPayCodes.UnloadColumn("PayCode"));
	Query.SetParameter("LinkOfCurrentDocument", Ref);
	
	Return Query.Execute().Unload();
	
EndFunction
	
#EndRegion

#EndIf
