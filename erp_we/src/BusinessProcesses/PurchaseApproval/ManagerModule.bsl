#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a structure with the name and parameters of the form opening
//
// Parameters:
//	TaskRef - TaskRef.PerformerTask - link to the task to get the form for
//	RoutePointRef - BusinessProcessRoutePointRef - link to
//							the business process route point to get the form for.
//
// Returns:
//	Structure - fields parameterform, formname.
//
Function TaskExecutionForm(Val TaskRef, Val RoutePointRef) Export
	
	If RoutePointRef = BusinessProcesses.PurchaseApproval.RoutePoints.ApproveLogisticConditions Or
		RoutePointRef = BusinessProcesses.PurchaseApproval.RoutePoints.ApproveFinancialConditions Or
		RoutePointRef = BusinessProcesses.PurchaseApproval.RoutePoints.ApprovePriceConditions Then
		FormName = "BusinessProcess.PurchaseApproval.Form.ReviewerTaskForm";
	ElsIf RoutePointRef = BusinessProcesses.PurchaseApproval.RoutePoints.ReadTheResults Then
		FormName = "BusinessProcess.PurchaseApproval.Form.TaskFormRead";
	ElsIf RoutePointRef = BusinessProcesses.PurchaseApproval.RoutePoints.SummarizeApproval Then
		FormName = "BusinessProcess.PurchaseApproval.Form.TaskFormSummarize";
	EndIf;
		
	Result = New Structure;
	Result.Insert("FormParameters", New Structure("Key", TaskRef));
	Result.Insert("FormName", FormName);
	
	Return Result;
	
EndFunction

// Called when executing a task from the list form.
// 
// Parameters:
//  TaskRef                - TaskRef.PerformerTask          - current running task
//  BusinessProcessRef         - BusinessProcessRef.PurchaseApproval - current approval process
//  BusinessProcessRoutePoint - BusinessProcessRoutePointRef       - approval route point
Procedure DefaultCompletionHandler(Val TaskRef, BusinessProcessRef, Val BusinessProcessRoutePoint) Export
	
	// setting default values for batch execution of tasks
	If BusinessProcessRoutePoint = BusinessProcesses.PurchaseApproval.RoutePoints.ApproveLogisticConditions Or
		BusinessProcessRoutePoint = BusinessProcesses.PurchaseApproval.RoutePoints.ApproveFinancialConditions Or
		BusinessProcessRoutePoint = BusinessProcesses.PurchaseApproval.RoutePoints.ApprovePriceConditions Or
		BusinessProcessRoutePoint = BusinessProcesses.PurchaseApproval.RoutePoints.SummarizeApproval Then
		
		Try
			LockDataForEdit(BusinessProcessRef);
		Except
				
			ErrorText = NStr("vi = 'Khi thực hiện nhiệm vụ không thể phong tỏa %Ref%. %ErrorDescription%';
							|ru = 'При выполнении задачи не удалось заблокировать %Ref%. %ErrorDescription%';
							|en = 'Cannot lock %Ref% when executing the task. %ErrorDescription%'; fa = 'Cannot lock %Ref% when executing the task. %ErrorDescription%';
							|it = 'Nell''eseguire il task non è stato possibile sbloccare %Ref%. %ErrorDescription%';
							|pl = 'Podczas wykonywania zadania nie udało się zablokować %Ref%. %ErrorDescription%';
							|tr = 'Görevin gerçekleştirilmesi sırasında %Ref% engellenemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Ref%",         BusinessProcessRef);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
				
			Raise ErrorText;
			
		EndTry;
		
		SetPrivilegedMode(True);
	
		ObjectApproval = BusinessProcessRef.GetObject();
		
		ObjectApproval.AddApprovalResult(
			BusinessProcessRoutePoint,
			Users.CurrentUser(),
			Enums.ApprovalResults.Approved,
			,
			CurrentSessionDate());
		
		If BusinessProcessRoutePoint = BusinessProcesses.PurchaseApproval.RoutePoints.SummarizeApproval Then
			ObjectApproval.ApprovalResult = Enums.ApprovalResults.Approved;
		EndIf;
		
		ObjectApproval.Write();
		SetPrivilegedMode(False);
		
		UnlockDataForEdit(BusinessProcessRef);

	EndIf;
	
EndProcedure

// Returns the result of approval by the reviewer for the route point
//
// Parameters:
//   BusinessProcess - BusinessProcessRef.PurchaseApproval - business approval process.
//   RoutePoint - BusinessProcessRoutePointRef - the point where the business process is located.
//
// Returns:
//   EnumRef.ApprovalResults - The result of coordination at the point of the route.
//
Function ResultOfCoordinationByRoutePoint(Val BusinessProcess, Val RoutePoint) Export
	
	Query = New Query("
		|SELECT
		|	PurchaseApprovalApprovalResults.ApprovalResult AS ApprovalResult
		|
		|FROM
		|	BusinessProcess.PurchaseApproval.ApprovalResults AS PurchaseApprovalApprovalResults
		|WHERE
		|	PurchaseApprovalApprovalResults.Ref = &Ref
		|	AND PurchaseApprovalApprovalResults.RoutePoint = &RoutePoint
		|");
		
	Query.SetParameter("Ref",        BusinessProcess);
	Query.SetParameter("RoutePoint", RoutePoint);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.ApprovalResult;
	Else
		Return Undefined;
	EndIf;
		
EndFunction

// Returns the number of the latest version of the item.
//
// Parameters:
//   BusinessProcess - BusinessProcessRef.PurchaseApproval - the business process for which the version number is obtained.
//
// Returns:
//   Number - The number of the latest version of the document.
//
Function LastVersionNumberOfItem(Val BusinessProcess) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
		|SELECT TOP 1
		|	ObjectsVersions.VersionNumber AS VersionNumber
		|FROM
		|	InformationRegister.ObjectsVersions AS ObjectsVersions
		|WHERE
		|	ObjectsVersions.Object = CAST (&BusinessProcess AS BusinessProcess.PurchaseApproval).SubjectOf
		|
		|ORDER BY
		|	VersionNumber DESC
		|
		|");
		
	Query.SetParameter("BusinessProcess", BusinessProcess);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		VersionNumber = Selection.VersionNumber;
	Else
		VersionNumber = 0;
	EndIf;
	
	Return VersionNumber;

EndFunction

// Checks for differences between the latest version of the item and the approved ones.
//
// Parameters:
//   BusinessProcess - BusinessProcessRef.PurchaseApproval - a business process whose subject is checked for differences.
//
// Returns:
//   Boolean - True, if there are differences, otherwise false.
//
Function LatestVersionOfItemIsDifferentFromAgreedOnes(Val BusinessProcess) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
		|SELECT
		|	ISNULL(MAX(ApprovalResults.VersionNumber),0) AS AgreedVersionNumber,
		|	ISNULL(MAX(ObjectsVersions.VersionNumber),0)         AS LastVersionNumber
		|FROM
		|	BusinessProcess.PurchaseApproval.ApprovalResults AS ApprovalResults
		|LEFT JOIN
		|	InformationRegister.ObjectsVersions AS ObjectsVersions
		|ON
		|	ObjectsVersions.Object = ApprovalResults.Ref.SubjectOf
		|WHERE
		|	ApprovalResults.Ref = &BusinessProcess
		|");
		
	Query.SetParameter("BusinessProcess", BusinessProcess);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		If Selection.AgreedVersionNumber <> Selection.LastVersionNumber Then
			ThereAreDifferences = True;
		Else
			ThereAreDifferences = False;
		EndIf;
	Else
		ThereAreDifferences = False;
	EndIf;
	
	Return ThereAreDifferences;
	
EndFunction

// Checks the versioning usage of the subject of approval
//
// Parameters:
//	SubjectType - String - the full name of the object, such as " Document.Client's order".
//
// Returns:
//	Boolean - True if versioning is used, otherwise false.
//
Function VersioningOfItemIsUsed(Val SubjectType) Export
	
	SetPrivilegedMode(True);
	
	UseObjectsVersioning = GetFunctionalOption("UseObjectsVersioning");
	
	If Not UseObjectsVersioning Then
		Return False;
	EndIf;
		
	OptionParameters_ = New Structure();
	OptionParameters_.Insert("ObjectType", SubjectType);
		
	UseObjectVersioning = GetFunctionalOption("UseObjectVersioning", OptionParameters_);
	
	Return UseObjectVersioning;
	
EndFunction

// Called when redirecting a task
//
// Parameters:
//   TaskRef      - TaskRef.PerformerTask - the forwarded task.
//   NewTaskRef - TaskRef.PerformerTask - task for a new performer.
//
Procedure OnForwardTask(TaskRef, NewTaskRef) Export
	
	TaskObject = NewTaskRef.GetObject(); // TaskObject.PerformerTask
	LockDataForEdit(NewTaskRef);
	TaskObject.ExecutionResult = ExecutionResultOnForward(TaskRef) + 
		TaskObject.ExecutionResult;
	TaskObject.Write();
	
EndProcedure

#EndRegion

#Region Private

#Region InfobaseUpdate

// Setting the values of the details of predefined elements in the roles of Executors directory
// related to the purchase agreement
// Called when the IB is initially filled in.
//
Procedure InitializeExecutorRoles() Export
	
	RoleObject1 = Catalogs.PerformerRoles.ApproverPurchasePriceTerms.GetObject();
	RoleObject1.UsedWithoutAddressingObjects = True;
	RoleObject1.Write();
	
	RoleObject1 = Catalogs.PerformerRoles.ApproverPurchaseLogisticsTerms.GetObject();
	RoleObject1.UsedWithoutAddressingObjects = True;
	RoleObject1.Write();
	
	RoleObject1 = Catalogs.PerformerRoles.ApproverPurchaseFinancialTerms.GetObject();
	RoleObject1.UsedWithoutAddressingObjects = True;
	RoleObject1.Write();
	
	RoleObject1 = Catalogs.PerformerRoles.ApproverPurchaseCommercialTerms.GetObject();
	RoleObject1.UsedWithoutAddressingObjects = True;
	RoleObject1.Write();
	
EndProcedure

#EndRegion

#Region Other

Function ExecutionResultOnForward(Val TaskRef)
	
	StringFormat = NStr("vi = '%1, %2 chuyển hướng nhiệm vụ:';
						|ru = '%1, %2 перенаправил(а) задачу:';
						|en = '%1, %2 forwarded the task:'; fa = '%1, %2 forwarded the task:';
						|it = '%1%2 ha reindirizzato il task:';
						|pl = '%1, %2 przekierował(a) zadanie:';
						|tr = '%1, %2 görevi yönlendirdi:'");
	StringFormat = StringFormat + Chars.LF + "%3" + Chars.LF;

	TaskDetails__ = Common.ObjectAttributesValues(TaskRef, "CompletionDate, Performer, ExecutionResult");
	
	Comment = TrimAll(TaskDetails__.ExecutionResult);
	Comment = ?(IsBlankString(Comment), "", Comment + Chars.LF);
	Result = StringFunctionsClientServer.SubstituteParametersToString(StringFormat,
		TaskDetails__.CompletionDate,
		TaskDetails__.Performer,
		Comment);
	
	Return Result;

EndFunction

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.PurchaseApprovalResults.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "BusinessProcessForm,ListForm";
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf


