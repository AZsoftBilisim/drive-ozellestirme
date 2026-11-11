#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)

	If Not Parameters.Filter.Property("Author") // The list is limited only when editing a document.
		Or UserRightsCached.ApprovePurchaseRequests() // The coordinator can perform any actions on the document
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

// Fill in the available Status routes ( State transitions) for Statuses
// 
// Parameters:
//  Form - ClientApplicationForm - Protocol Owner
Procedure FillInAvailableStatusRoutes(Form) Export
	
	ApprovalIsAvailable = UserRightsCached.ApprovePurchaseRequests();
	ClosureIsAvailable = ApprovalIsAvailable Or Form.Object.Author = Users.CurrentUser();

	#Region AwaitingApproval
	
	If UserRightsCached.ApprovePurchaseRequests() Then
		OperationsWithDocumentProtocol.AddAvailableRoute(
			Form,
			AwaitingApproval,
			OnExecution,
			NStr("ru = 'Передать на выполнение';
				|vi = 'Send for execution';
				|en = 'Send for execution'; fa = 'ارسال برای اجرا';
				|it = 'Send for execution';
				|pl = 'Send for execution';
				|tr = 'Uygulamaya gönder'"),
			"Manager");
	EndIf;

	OperationsWithDocumentProtocol.AddRedirectionRoute(Form, AwaitingApproval);
	AddClosure(Form, AwaitingApproval, ClosureIsAvailable);
	
	#EndRegion

	#Region OnExecution
	
	AddClosure(Form, OnExecution, ClosureIsAvailable);
	
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
			|tr = 'Onaya geri gönder'"),
		"EmployeeResponsible");

	#EndRegion

	#Region Closed_
	
	OperationsWithDocumentProtocol.AddAvailableRoute(
		Form,
		Closed_,
		OnExecution,
		NStr("ru = 'Вернуть в работу';
			|vi = 'Return';
			|en = 'Return'; fa = 'مرجوعی';
			|it = 'Return';
			|pl = 'Return';
			|tr = 'Çalışmaya geri gönder'"),
		"Manager");
		
	#EndRegion
			
EndProcedure

Procedure AddClosure(Form, InitialStatus, ClosureIsAvailable)
	
	If Not ClosureIsAvailable Then
		Return;
	EndIf;
	
	OperationsWithDocumentProtocol.AddAvailableRoute(Form, InitialStatus, Closed_, NStr("ru = 'Закрыть заявку';
																						|vi = 'Close request';
																						|en = 'Close request'; fa = 'بستن درخواست';
																						|it = 'Chiudi la richiesta';
																						|pl = 'Zamknij zgłoszenie';
																						|tr = 'Talebi kapat'"));
	
EndProcedure

#EndRegion

#Region FinalStatuses

// This is the final Status.
// 
// Parameters:
//  Status - EnumRef.PurchaseRequestStatuses - the Status being checked.
// 
// Returns:
//  Boolean - This is the final Status of the work on the document
Function ThisIsFinalStatus(Status) Export
	
	Return FinalStatuses().Find(Status) <> Undefined;
	
EndFunction

// The final Status of working with the document.
// 
// Returns:
//  Array of EnumRef.PurchaseRequestStatuses
Function FinalStatuses() Export
	
	FinalStatuses = New Array;
	FinalStatuses.Add(PredefinedValue("Enum.PurchaseRequestStatuses.Closed_"));
	
	Return FinalStatuses;
	
EndFunction 

// This is the Status that has been approved
// 
// Parameters:
//  Status - EnumRef.PurchaseRequestStatuses - the Status being checked.
// 
// Returns:
//  Boolean
Function AgreedUpon(Status) Export
	
	StatusesThatHaveBeenApproved = New Array;
	
	StatusesThatHaveBeenApproved.Add(OnExecution);
	StatusesThatHaveBeenApproved.Add(Closed_);
	
	Return StatusesThatHaveBeenApproved.Find(Status) <> Undefined 
	
EndFunction

#EndRegion

#EndRegion

#EndIf
