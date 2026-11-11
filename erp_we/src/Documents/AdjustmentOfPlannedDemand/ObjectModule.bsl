#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfPlanAdjustments[NewStatus];
	
	Status = MeaningOfNewStatus;
	
	Return CheckFilling();
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	DocumentPlan = Undefined;
	
	If FillInDataType = Type("Structure") Then
		
		FillPropertyValues(ThisObject, FillingData);
		
		If FillingData.Property("Products") Then
			NewRow = DecreasedDemands.Add();
			NewRow.Products = FillingData.Products;
			NewRow.Characteristic = FillingData.Characteristic;
			NewRow.Purpose = FillingData.Purpose;
			NewRow.Count = FillingData.Count;
		EndIf;
		
		FillingData.Property("Plan", DocumentPlan);
		
	ElsIf FillInDataType = Type("DocumentRef.PurchasePlan")
		Or FillInDataType = Type("DocumentRef.ProductionPlan")
		Or FillInDataType = Type("DocumentRef.AssemblyDisassemblyPlan") Then
		
		DocumentPlan = FillingData;
		
	EndIf;
	
	If DocumentPlan <> Undefined Then
		DocumentAttributes = Common.ObjectAttributesValues(DocumentPlan, "Scenario, PlanProfile, Ref, BeginOfPeriod");
		
		Scenario = DocumentAttributes.Scenario;
		PlanProfile = DocumentAttributes.PlanProfile;
		Plan = DocumentAttributes.Ref;
		Period = DocumentAttributes.BeginOfPeriod;
	EndIf;
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.TSName = "DecreasedDemands";
	CheckParameters.CheckPossibilityOfRounding = False;
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.TSName = "IncreasedDemand";
	CheckParameters.CheckPossibilityOfRounding = False;
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	If AdjustmentInputModeMultiline Then
		
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "DecreasedDemands";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "IncreasedDemand";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		
	Else
		
		NotCheckedAttributeArray.Add("IncreasedDemand.Characteristic");
		NotCheckedAttributeArray.Add("DecreasedDemands.Characteristic");
		
	EndIf;

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	AdditionalProperties.Insert("IsNew",    IsNew());
	AdditionalProperties.Insert("WriteMode", WriteMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	If Not Cancel
		And Common.ObjectAttributeValue(Scenario,"PlanningProcessManagement") Then
		
		Planning.RunningBackgroundCheckForCalculatingDeficitInStages(Scenario, PlanProfile);
		
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	If Not Cancel
		And Common.ObjectAttributeValue(Scenario,"PlanningProcessManagement") Then
		
		Planning.RunningBackgroundCheckForCalculatingDeficitInStages(Scenario, PlanProfile);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible			= UsersClientServer.CurrentUser();
	Date					= CurrentSessionDate();
	
EndProcedure

#EndRegion

#EndIf
