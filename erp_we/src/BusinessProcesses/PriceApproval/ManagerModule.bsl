#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a structure with the name and parameters of the form opening
//
// Parameters:
//  TaskRef - TaskRef.PerformerTask - link to the task to get the form for
//  RoutePointRef - BusinessProcessRoutePointRef.ApprovalOfRequestForReturnOfGoodsFromCustomer - link
//                                                   to the business process route point to get the form for.
//
// Returns:
//  Structure - with properties:
//  * FormParameters - Structure - with properties:
//    ** Key - TaskRef - Link to the issue
//  * FormName - String - The name of the form.
//
Function TaskExecutionForm(Val TaskRef, Val RoutePointRef) Export
	
	If RoutePointRef = BusinessProcesses.PriceApproval.RoutePoints.ReadTheResults Then
		FormName = "BusinessProcess.PriceApproval.Form.TaskFormRead";
	ElsIf RoutePointRef = BusinessProcesses.PriceApproval.RoutePoints.ApproveProductPricing Then
		FormName = "BusinessProcess.PriceApproval.Form.ReviewerTaskForm";
	EndIf;
	
	Result = New Structure;
	Result.Insert("FormParameters", New Structure("Key", TaskRef));
	Result.Insert("FormName", FormName);
	
	Return Result;
	
EndFunction

// Called when executing a task from the list form
//
// Parameters:
//	TaskRef                - TaskRef.PerformerTask - Task
//	BusinessProcessRef         - BusinessProcessRef.PriceApproval - 
//	BusinessProcessRoutePoint - BusinessProcessRoutePointRef.PriceApproval - 
//
Procedure DefaultCompletionHandler(Val TaskRef, BusinessProcessRef, Val BusinessProcessRoutePoint) Export
	
	// setting default values for batch execution of tasks
	If BusinessProcessRoutePoint = BusinessProcesses.PriceApproval.RoutePoints.ApproveProductPricing Then
		
		Try
			LockDataForEdit(BusinessProcessRef);
		Except
				
			ErrorText = NStr("vi = 'Khi thực hiện nhiệm vụ không thể phong tỏa %Ref%.%ErrorDescription%';
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
		
		ObjectApproval.ApprovalResult = Enums.ApprovalResults.Approved;
		
		ObjectApproval.Write();
		SetPrivilegedMode(False);
		
		UnlockDataForEdit(BusinessProcessRef);

	EndIf;
	
EndProcedure

// Returns the result of approval by the reviewer for the route point
//
// Parameters:
//	BusinessProcess - BusinessProcessRef.PriceApproval - 
//	RoutePoint - BusinessProcessRoutePointRef.PriceApproval - 
//
// Returns:
//	EnumRef.ApprovalResults - The result of coordination at the point of the route.
//
Function ResultOfCoordinationByRoutePoint(Val BusinessProcess, Val RoutePoint) Export
	
	Query = New Query("
		|SELECT
		|	PriceApprovalApprovalResults.ApprovalResult AS ApprovalResult
		|
		|FROM
		|	BusinessProcess.PriceApproval.ApprovalResults AS PriceApprovalApprovalResults
		|WHERE
		|	PriceApprovalApprovalResults.Ref = &Ref
		|	AND PriceApprovalApprovalResults.RoutePoint = &RoutePoint
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

// Returns the number of the latest version of the item
//
// Parameters:
//    BusinessProcess - BusinessProcessRef.PriceApproval - 
//
// Returns:
//    Number - The number of the latest version of the document.
//
Function LastVersionNumberOfItem(Val BusinessProcess) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
		|SELECT TOP 1
		|	ObjectsVersions.VersionNumber AS VersionNumber
		|FROM
		|	InformationRegister.ObjectsVersions AS ObjectsVersions
		|WHERE
		|	ObjectsVersions.Object = CAST (&BusinessProcess AS BusinessProcess.PriceApproval).SubjectOf
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

// Checks for differences between the latest version of the item and the approved ones
//
// Parameters:
//	BusinessProcess - BusinessProcessRef.PriceApproval - 
//
// Returns:
//	Boolean - True, if there are differences, otherwise false.
//
Function LatestVersionOfItemIsDifferentFromAgreedOnes(Val BusinessProcess) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
		|SELECT
		|	MAX(ApprovalResults.VersionNumber)     AS AgreedVersionNumber,
		|	ISNULL(MAX(ObjectsVersions.VersionNumber),0) AS LastVersionNumber
		|FROM
		|	BusinessProcess.PriceApproval.ApprovalResults AS ApprovalResults
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
//	TaskRef  - TaskRef.PerformerTask - the forwarded task.
//	NewTaskRef  - TaskRef.PerformerTask - task for a new performer.
//
Procedure OnForwardTask(TaskRef, NewTaskRef) Export
	
	Return;
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE TRUE
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Author)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

// Setting the values of the details of predefined elements in the roles of Performers directory that
// relate to the approval of the item price setting.
//
Procedure InitializeExecutorRoles() Export
	
	RoleObject1 = Catalogs.PerformerRoles.ApproverProductPricing.GetObject();
	RoleObject1.UsedWithoutAddressingObjects = True;
	RoleObject1.Write();
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.ResultsOfProductsPriceApproval.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "BusinessProcessForm,ListForm";
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf


