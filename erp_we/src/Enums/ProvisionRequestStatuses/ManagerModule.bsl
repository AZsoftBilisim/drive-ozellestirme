#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not Parameters.Filter.Property("Author") // The list is limited only when editing a document.
		Or UserRightsCached.ApproveProvisionRequests() // The coordinator can perform any actions on the document
		Then
		Return;
	EndIf;
		
	StandardProcessing = False;
	ExcludedValues = New Array;
	ExcludedValues.Add(OnExecution); // Approval ban.
	
	If Parameters.Filter.Author <> Users.CurrentUser() Then
		// Closing ban.
		CommonClientServer.SupplementArray(ExcludedValues, FinalStatuses());
	EndIf;
	
	TMCommonUse.SelectableEnumerationValues(
		EmptyRef().Metadata().Name,
		ChoiceData,
		Parameters,
		ExcludedValues);

EndProcedure

#EndRegion

#Region Private

#Region AvailableRoutes

Procedure FillInAvailableStatusRoutes(Form) Export

	ApprovalIsAvailable = UserRightsCached.ApproveProvisionRequests();
	ClosureIsAvailable = ApprovalIsAvailable Or Form.Object.Author = Users.CurrentUser();

	#Region Draft
	
	OperationsWithDocumentProtocol.AddAvailableRoute(
		Form,
		Draft,
		AwaitingApproval,
		NStr("vi = 'Gửi để thống nhất';
			|ru = 'Отправить на согласование';
			|en = 'Send for approval'; fa = 'ارسال برای تأیید';
			|it = 'Invia per l''approvazione';
			|pl = 'Wyślij do uzgodnienia';
			|tr = 'Onay için gönder'"),
		"EmployeeResponsible");

	AddCancellation(Form, Draft, ClosureIsAvailable);

#EndRegion

#Region AwaitingApproval
	
	If ApprovalIsAvailable Then
		OperationsWithDocumentProtocol.AddAvailableRoute(
			Form,
			AwaitingApproval,
			OnExecution,
			NStr("ru = 'Передать на выполнение';
				|vi = 'Send for execution';
				|en = 'Send for execution'; fa = 'ارسال برای اجرا';
				|it = 'Send for execution';
				|pl = 'Send for execution';
				|tr = 'Uygulamaya gönder'"));
			
	EndIf;
	
	OperationsWithDocumentProtocol.AddRedirectionRoute(Form, AwaitingApproval);
	AddCancellation(Form, AwaitingApproval, ClosureIsAvailable);

#EndRegion

#Region OnExecution
	
	If ClosureIsAvailable Then
		
		OperationsWithDocumentProtocol.AddAvailableRoute(
			Form,
			OnExecution,
			Executed,
			NStr("ru = 'Отметить выполнение';
				|vi = 'Mark as completed';
				|en = 'Mark as completed'; fa = 'علامت‌گذاری به‌عنوان تکمیل‌شده';
				|it = 'Segnare completamento';
				|pl = 'Zaznacz wykonanie';
				|tr = 'Gerçekleştirmeyi işaretle'"));
			
	EndIf;
	
	OperationsWithDocumentProtocol.AddRedirectionRoute(Form, OnExecution);
	
	OperationsWithDocumentProtocol.AddAvailableRoute(
		Form,
		OnExecution,
		AwaitingApproval,
		NStr("ru = 'Вернуть на согласование';
			|vi = 'Return for approval';
			|en = 'Return for approval'; fa = 'Return for approval';
			|it = 'Return for approval';
			|pl = 'Return for approval';
			|tr = 'Çalışmaya geri gönder'"),
		"EmployeeResponsible");
		
	AddCancellation(Form, OnExecution, ClosureIsAvailable);

#EndRegion

#Region RolledBack
	
	OperationsWithDocumentProtocol .AddAvailableRoute(
		Form,
		RolledBack,
		Draft,
		NStr("ru = 'Вернуть в черновик';
			|vi = 'Return to Draft';
			|en = 'Return to Draft'; fa = 'Return to Draft';
			|it = 'Return to Draft';
			|pl = 'Return to Draft';
			|tr = 'Taslaklara geri gönder'"),
		"Author");

#EndRegion

#Region Executed

	If ApprovalIsAvailable Then
		OperationsWithDocumentProtocol.AddAvailableRoute(Form, Executed, OnExecution, NStr("ru = 'Вернуть в работу';
																							|vi = 'Return';
																							|en = 'Return'; fa = 'مرجوعی';
																							|it = 'Return';
																							|pl = 'Return';
																							|tr = 'Çalışmaya geri gönder'"));
	Else
		OperationsWithDocumentProtocol.AddAvailableRoute(Form, Executed, Draft, NStr("ru = 'Вернуть в черновик';
																					|vi = 'Return to draft';
																					|en = 'Return to draft'; fa = 'Return to draft';
																					|it = 'Return to draft';
																					|pl = 'Return to draft';
																					|tr = 'Taslaklara geri gönder'"));
	EndIf;
	
	AddCancellation(Form, Executed, ClosureIsAvailable);
	
#EndRegion

EndProcedure

Procedure AddCancellation(AvailableRoutes, InitialStatus, ClosureIsAvailable)
	
	If Not ClosureIsAvailable Then
		Return;
	EndIf;
	
	OperationsWithDocumentProtocol.AddAvailableRoute(AvailableRoutes, InitialStatus, RolledBack, NStr("ru = 'Отменить заявку';
																										|vi = 'Cancel request';
																										|en = 'Cancel request'; fa = 'Cancel request';
																										|it = 'Cancel request';
																										|pl = 'Cancel request';
																										|tr = 'Talebi iptal et'"));
	
EndProcedure

#EndRegion

#Region FinalStatuses

// This is the final Status.
// 
// Parameters:
//  Status - EnumRef.ProvisionRequestStatuses- the Status being checked.
// 
// Returns:
//  Boolean - This is the final Status of the work on the document
Function ThisIsFinalStatus(Status) Export

	Return FinalStatuses().Find(Status) <> Undefined;

EndFunction

// The final Status of working with the document.
// 
// Returns:
//  Array of EnumRef.ProvisionRequestStatuses
Function FinalStatuses() Export
	
	FinalStatuses = New Array;
	
	FinalStatuses.Add(Executed);
	FinalStatuses.Add(RolledBack);
	
	Return FinalStatuses;
	
EndFunction

#EndRegion

// The Status requires a document.
// 
// Parameters:
//  Status - EnumRef.ProvisionRequestStatuses - the Status being checked.
// 
// Returns:
//  Boolean
Function Post(Status) Export
	
	StatusOfEvent = New Array;
	
	StatusOfEvent.Add(AwaitingApproval);
	StatusOfEvent.Add(OnExecution);
	StatusOfEvent.Add(Executed);
	
	Return StatusOfEvent.Find(Status) <> Undefined;
	
EndFunction

// This is the Status that has been approved
// 
// Parameters:
//  Status - EnumRef.ProvisionRequestStatuses - the Status being checked.
// 
// Returns:
//  Boolean
Function AgreedUpon(Status) Export
		
	Return StatusesThatHaveBeenApproved().Find(Status) <> Undefined 
	
EndFunction

// Statuses that have been approved.
// 
// Returns:
//  Array of EnumRef.ProvisionRequestStatuses - Statuses That Have Been Approved
Function StatusesThatHaveBeenApproved() Export
	
	StatusesThatHaveBeenApproved = New Array;
	
	StatusesThatHaveBeenApproved.Add(OnExecution);
	StatusesThatHaveBeenApproved.Add(Executed);
	
	Return StatusesThatHaveBeenApproved;
	
EndFunction

#EndRegion

#EndIf
