#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("Budgeting");
	DocumentMechanisms.Add("InventoryPlanning");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * Table - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.PurchasePlan") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTablePurchasePlans(Query, QueryTexts, Registers);
		QueryTextTableCashFlowPlansVendors(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	
	Documents.AdjustmentOfPlannedDemand.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the command to create the "purchase Plan" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.PurchasePlan) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PurchasePlan.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PurchasePlan);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePurchasePlanning";
	

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.PlansEquilibriumTM.AddBalancedPlansTeam(ReportsCommands);
	
	Reports.PurchasePlan.AddPurchasePlanTeam(ReportsCommands);
	
EndProcedure

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef.PlanStatuses - New plan status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks for the "Purchase Plan" document
	
EndFunction

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.PlanStatuses[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.PurchasePlan AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)
	|ORDER BY
	|	Date
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Forms the structure of additional details for the document
//
// Parameters:
// Parameters     - Structure - Values of additional banking details
// AddlParameters  - Structure - The composition of operands for the specified type of plan and scenario.
//
Procedure AdditionalParametersForFormulaCalculation(Parameters, AddlParameters) Export
	
	PlanProfile				= Parameters.TypeOfPlanDetails;
	Scenario 				= Parameters.ScenarioDetails;
	AttributePath1			= Parameters.AttributePath1;
	
	ThisIsProcurementPlan			  = PlanProfile.PlanType = Enums.TypesOfPlans.PurchasePlan;
	ThisIsTheRemainderPlan 		  = PlanProfile.PlanType = Enums.TypesOfPlans.PlanOfGoodsStock;
	CreatePropsWithSelection = PlanProfile.FillInPartner 
		Or PlanProfile.FillInTermsOfSales 
		Or PlanProfile.FillInWarehouse 
		Or (PlanProfile.FillInBusinessUnit And ThisIsProcurementPlan)
		Or (Scenario.PlanningByAssignments And Not PlanProfile.FillInAssignmentInTabularForm);
	UseProcurementPlans 						= GetFunctionalOption("UsePurchasePlanning") And Scenario.UseInPurchasePlanning;
	UseRemainderPlans 						= GetFunctionalOption("UsePlanningOfGoodsStock") And Scenario.UseInBalancePlanning;
	ReadingProcurementFact								= AccessRight("Read", Metadata.AccumulationRegisters.Purchases);
	
#Region PurchasePlans
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"PurchasePlans");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch mua hàng';
													|ru = 'План закупок';
													|en = 'Purchase plan'; fa = 'برنامه خرید';
													|it = 'Piano di acquisti';
													|pl = 'Plan zakupów';
													|tr = 'Satın alma planı'"));
	AddnlParameter_.Insert("CreateProps", 	UseProcurementPlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseProcurementPlans);
	AddnlParameter_.Insert("OperandHeader",	NStr("vi = 'Kế hoạch mua hàng';
													|ru = 'План закупок';
													|en = 'Purchase plan'; fa = 'برنامه خرید';
													|it = 'Piano di acquisti';
													|pl = 'Plan zakupów';
													|tr = 'Satın alma planı'"));
	AddnlParameter_.Insert("Details", 		"Document.PurchasePlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("PurchasePlans", AddnlParameter_);
#EndRegion
	
#Region PurchasePlansWithSelection
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"PurchasePlansWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch mua hàng*';
													|ru = 'План закупок*';
													|en = 'Purchase plan*'; fa = 'Purchase plan*';
													|it = 'Piano di acquisti*';
													|pl = 'Plan zamówień *';
													|tr = 'Satın alma planı*'"));
	AddnlParameter_.Insert("CreateProps", 	UseProcurementPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseProcurementPlans And CreatePropsWithSelection);
	AddnlParameter_.Insert("OperandHeader",	NStr("vi = 'Kế hoạch mua hàng*';
													|ru = 'План закупок*';
													|en = 'Purchase plan*'; fa = 'Purchase plan*';
													|it = 'Piano di acquisti*';
													|pl = 'Plan zamówień *';
													|tr = 'Satın alma planı*'"));
	AddnlParameter_.Insert("Details", 		"Document.PurchasePlan");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("PurchasePlansWithSelection", AddnlParameter_);
#EndRegion
	
#Region PurchaseFacts
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"PurchaseFacts");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			?(CreatePropsWithSelection, NStr("vi = 'Thực tế mua hàng*';
																				|ru = 'Факт закупок*';
																				|en = 'Actual purchases*'; fa = 'Actual purchases*';
																				|it = 'Fatto di acquisti*';
																				|pl = 'Fakt zamówień*';
																				|tr = 'Satın alma gerçekleri*'"), NStr("vi = 'Thực tế mua hàng';
																													|ru = 'Факт закупок';
																													|en = 'Actual purchases'; fa = 'خریدهای واقعی';
																													|it = 'Fatto di acquisti';
																													|pl = 'Fakt zamówień';
																													|tr = 'Satın alma gerçekleri'")));
	AddnlParameter_.Insert("CreateProps", 	ReadingProcurementFact);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	ReadingProcurementFact);
	AddnlParameter_.Insert("OperandHeader", 	?(CreatePropsWithSelection, NStr("vi = 'Thực tế mua hàng*';
																				|ru = 'Факт закупок*';
																				|en = 'Actual purchases*'; fa = 'Actual purchases*';
																				|it = 'Fatto di acquisti*';
																				|pl = 'Fakt zamówień*';
																				|tr = 'Satın alma gerçekleri*'"), NStr("vi = 'Thực tế mua hàng';
																													|ru = 'Факт закупок';
																													|en = 'Actual purchases'; fa = 'خریدهای واقعی';
																													|it = 'Fatto di acquisti';
																													|pl = 'Fakt zamówień';
																													|tr = 'Satın alma gerçekleri'")));
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsFacts");
	
	AddlParameters.Insert("PurchaseFacts", AddnlParameter_);
#EndRegion

EndProcedure

// Returns the operand layouts for this plan
//
// Parameters:
//  Templates  - Map - A General list of layouts to which layouts for this document are added.
//
// Returns:
//   Map   - Layouts for operands.
//
Function PlanOperandTemplates(Templates = Undefined) Export

	If Templates = Undefined Then
		Templates = New Map;
	EndIf; 
	
	Templates.Insert("PurchasePlans",                   GetTemplate("DCS_PurchasePlans"));
	Templates.Insert("PurchasePlansWithSelection",           GetTemplate("DCS_PurchasePlansWithSelection"));
	Templates.Insert("PurchaseFacts",                   GetTemplate("DCS_PurchaseFacts"));
	Templates.Insert("PurchaseAssortment",             GetTemplate("DCS_PurchaseAssortment"));
	Templates.Insert("ProductCrossReferences",        GetTemplate("DCS_ProductCrossReferences"));
	Templates.Insert("GoodsPurchasedFromSupplier", GetTemplate("DCS_GoodsPurchasedFromSupplier"));
	Templates.Insert("ItemsPricesOfVendor",    GetTemplate("DCS_ItemsPricesOfVendor"));
	Templates.Insert("MinimumSupplierPrice",      GetTemplate("DCS_MinimumSupplierPrice"));
	
	Return Templates;

EndFunction

// The procedure fills in the tabular part of the document using formulas or a rule for filling in planning data sources
// . it is intended for filling in the document in the background.
//
// Parameters:
//  Parameters  - Structure - Settings to fill in
//  StorageAddress - String - The address of the temporary storage where the result of the task will be placed
//  StorageAddressAdditional - String
//
Procedure FillInDocument(Val Parameters, Val StorageAddress, Val StorageAddressAdditional = "") Export
	
	Settings = Common.CommonSettingsStorageLoad(Parameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+Parameters.UUID);
	
	If TypeOf(Settings) <> Type("Structure") Then
		
		Return;
		
	EndIf;
	
	Parameters.Insert("TimeIntervals", Settings.TimeIntervals);
	
	If Parameters.Property("FillInUsingFormula") Then
		
		Parameters.Insert("PopulatedTS", Settings.PopulatedTS);
		FillInDocumentUsingFormula(Parameters, StorageAddress, StorageAddressAdditional);
		
		
	ElsIf Parameters.Property("FillInRule") Then
		
		Parameters.Insert("FillingRule", Settings.FillingRule);
		Parameters.Insert("UserSettings", Settings.UserSettings);
		Parameters.Insert("PopulatedTS", Settings.PopulatedTS);
		
		FillInAccordingToTheFillingRule(Parameters, StorageAddress);
		
	ElsIf Parameters.Property("FillInForReplacement") Then
		
		Parameters.Insert("PopulatedTS", Settings.PopulatedTS);
		FillInReplacementDocument(Parameters, StorageAddress);
		
	EndIf;
	
	SetPrivilegedMode(True);
	Common.CommonSettingsStorageDelete(Parameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+Parameters.UUID, Users.CurrentUser());
	
EndProcedure

// The procedure fills in the tabular part of the document using formulas
// Parameters:
//  Parameters  - Structure - Settings to fill in:
//  	* PopulatedTS - ValueTable -
//  StorageAddress - String - The address of the temporary storage where the result of the task will be placed
//  StorageAddressAdditional - String
//
Procedure FillInDocumentUsingFormula(Val Parameters, Val StorageAddress, Val StorageAddressAdditional) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.PurchasePlan.ManagerModule.FillInDocumentUsingFormula");
	
	If Not Parameters.Property("FillInUsingFormula") Then
		Return;
	EndIf; 
	
	PeriodColumnName = "DateOfReceipt";
	
	TimeIntervals = Parameters.TimeIntervals;
	Planning.PrepareTableOfPeriodsBeforeFillingIn(Parameters);
	Planning.FillInPeriodTable(TimeIntervals, Parameters.Periodicity, Parameters.OffsetPeriodStart, Parameters.OffsetPeriodEnd,,, Parameters.ActivePeriodStart);
	
	FoundPeriodStrings = TimeIntervals.FindRows(New Structure("Active_", True));
	TotalPeriods = FoundPeriodStrings.Count();
	If Parameters.CrossTable And TotalPeriods = 0 Then 
		
		PutToTempStorage(New ValueTable, StorageAddress);
		PutToTempStorage(Undefined, StorageAddressAdditional);

		Return;
		
	EndIf;
	
	Parameters.Insert("TimeIntervals", TimeIntervals); 
	
	PopulatedTS = Parameters.PopulatedTS;
	
	PeriodColumn = PopulatedTS.Columns[PeriodColumnName]; // ValueTableColumn - 
	PeriodColumn.Name = "CompositionPeriod";
	
	Result = Planning.FillInFormula(Parameters);
	
	If Result.Columns.Find("CompositionPeriod") = Undefined Then
		Result.Columns.Add("CompositionPeriod", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date))
	EndIf; 
	
	Result.Columns["CompositionPeriod"].Name = PeriodColumnName;
	PutToTempStorage(Result, StorageAddress);
	If Parameters.ActivePeriodStart > Parameters.OffsetPeriodStart Then
		PutToTempStorage(TimeIntervals, StorageAddressAdditional);
	Else
		PutToTempStorage(Undefined, StorageAddressAdditional);
	EndIf;
	
	ProcessedItemsCount = TimeIntervals.Count();
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ProcessedItemsCount);
	
EndProcedure

// The procedure fills in the tabular part of the document according to the filling rule from various sources.
//
// Parameters:
//  Parameters  - Structure - Settings to fill in:
//  	* PopulatedTS - ValueTable -
//  	* TimeIntervals See Planning.TablePeriods
//  StorageAddress - String - Address of the temporary storage where the task result will be placed
//  Settings-Structure-Additional settings for filling, filling Rule, user settings, PM
//                           filling.
//
Procedure FillInAccordingToTheFillingRule(Val Parameters, Val StorageAddress) Export
	
	If Not Parameters.Property("FillInRule") Then
		Return;
	EndIf; 
	
	PeriodColumnName = "DateOfReceipt";
	
	TimeIntervals = Parameters.TimeIntervals;
	
	FoundPeriodStrings = TimeIntervals.FindRows(New Structure("Active_", True));
	TotalPeriods = FoundPeriodStrings.Count();
	If Parameters.CrossTable And TotalPeriods = 0 Then 
		
		Return;
		
	EndIf;
	
	Coefficients = New Array;
	For IndexOf = 1 To TotalPeriods Do
		Coefficients.Add(1);
	EndDo;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DataParameters", Planning.GetPlanParameters(Parameters));
	If Parameters.Property("Filter") Then
		AdditionalParameters.Insert("Filter", Parameters.Filter);
	EndIf;
	
	If ValueIsFilled(Parameters.ChangeResultTo) Then
		
		AdditionalParameters.DataParameters.Insert("ZoomRatio", (100 + Parameters.ChangeResultTo) / 100);
		
	EndIf;
	
	If Parameters.Property("RoundingPrecision") Then
		AdditionalParameters.DataParameters.Insert("RoundingPrecision", Parameters.RoundingPrecision);
	EndIf;
	
	FillingRule = Parameters.FillingRule;
	UserSettings = Parameters.UserSettings;
	
	
	Result = Planning.SelectDataByRules(
		Enums.TypesOfPlans.PurchasePlan, 
		FillingRule, 
		UserSettings, 
		AdditionalParameters);
	
	PopulatedTS = Parameters.PopulatedTS;
	
	If Result <> Undefined Then
		
		BitRounding = Parameters.RoundingPrecision + 3;
		
		For Each ResultString1 In Result Do
			
			If Parameters.RoundingPrecision <> 0 Then
				FunctionName = NStr("vi = 'Làm tròn(%1; %2)';
									|ru = 'Окр(%1; %2)';
									|en = 'Round(%1; %2)'; fa = 'Round(%1; %2)';
									|it = 'Окр(%1; %2)';
									|pl = 'Round(%1; %2)';
									|tr = 'Yuv(%1; %2)'");
				ResultString1.Details = StringFunctionsClientServer.SubstituteParametersToString(FunctionName, ResultString1.Details, Pow(10, -BitRounding));
				ResultString1.NumericalRepresentation = StringFunctionsClientServer.SubstituteParametersToString(FunctionName, ResultString1.NumericalRepresentation, Pow(10, -BitRounding));
			EndIf;
			
			If ResultString1.Count = null Then
				Continue;
			EndIf;
			
			If Int(ResultString1.Count * Pow(10, BitRounding)) = 0 Then
				
				Continue;
				
			EndIf;
			
			Count = Round(ResultString1.Count, BitRounding);
			
			If Parameters.CrossTable Then
				
				If ValueIsFilled(ResultString1.Period) 
					And ResultString1.Period >= Parameters.BeginOfPeriod 
					And ResultString1.Period <= Parameters.PeriodEnding Then
					
					// It is not necessary to distribute by periods
					ResultString1.Details = ResultString1.Details + " = " + ResultString1.NumericalRepresentation;
				
					If ResultString1.NumericalRepresentation <> String(Count) Then
						ResultString1.Details = ResultString1.Details + " = " + String(Count);
					EndIf;
					
					NewRow = PopulatedTS.Add();
					FillPropertyValues(NewRow, ResultString1);
					
					NewRow.Count = Count;
					NewRow.NumberOfPackages = NewRow.Count;
					NewRow[PeriodColumnName] = ResultString1.Period;
					
					Continue;
					
				ElsIf ValueIsFilled(ResultString1.Period) Then
					// Exclude the line because it does not fall within the specified period of the plan
					Continue;
					
				EndIf; 
				
				If ResultString1.Count < 0 Then
					QuantitySign = -1;
				Else
					QuantitySign = 1;
				EndIf;
				
				QuantityDistribution = Planning.DistributeAmountInProportionToCoefficients(QuantitySign * ResultString1.Count, Coefficients, BitRounding);
				If QuantityDistribution = Undefined Then
					
					ResultString1.Details = ResultString1.Details + " = " + ResultString1.NumericalRepresentation;
					
					If ResultString1.NumericalRepresentation <> String(Count) Then
						ResultString1.Details = ResultString1.Details + " = " + String(Count);
					EndIf;
					
					Continue;
				EndIf; 
				
				// With a uniform distribution, the remainder of the rounding is subtracted from the first element, so we reset it if it went into negative.
				If QuantityDistribution[0] < 0 Then
					QuantityDistribution[0] = 0;
				EndIf;
				
				ResultString1.Details = "(" + ResultString1.Details + ") * " + NStr("vi = 'Hệ số phân bổ';
																					|ru = 'Коэфф распределения';
																					|en = 'Allocation factor'; fa = 'Allocation factor';
																					|it = 'Коэфф распределения';
																					|pl = 'Allocation factor';
																					|tr = 'Dağılım katsayısı'");
				ResultString1.NumericalRepresentation = "(" + ResultString1.NumericalRepresentation + ") * ";
				// The distribution is made starting from the last element, because the first one may be smaller than the others.
				IndexOf = QuantityDistribution.UBound();
				While IndexOf >= 0 Do
				
					Count = QuantityDistribution[IndexOf];
					PeriodDate_ = FoundPeriodStrings[FoundPeriodStrings.UBound() - IndexOf].StartDate;
					IndexOf = IndexOf - 1;
					
					If Count = 0 Then
						Continue;
					EndIf;
					
					NewRow = PopulatedTS.Add();
					FillPropertyValues(NewRow, ResultString1);
					
					NewRow.Count = QuantitySign * Count;
					NewRow.NumberOfPackages = NewRow.Count;
					NewRow[PeriodColumnName] = PeriodDate_;
					
					NewRow.Details = ResultString1.Details + " = "
						+ ResultString1.NumericalRepresentation
						+ String(Round(NewRow.Count/ResultString1.Count, 3, 1))
						+ " = " + String(NewRow.Count);
				EndDo; 
				
			Else
				
				ResultString1.Details = ResultString1.Details + " = " + ResultString1.NumericalRepresentation;
				
				If ResultString1.NumericalRepresentation <> String(Count) Then
					ResultString1.Details = ResultString1.Details + " = " + String(Count);
				EndIf;
			
				NewRow = PopulatedTS.Add();
				FillPropertyValues(NewRow, ResultString1);
				NewRow.Count = Count;
				NewRow.NumberOfPackages = NewRow.Count;
				NewRow[PeriodColumnName] = ResultString1.Period;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	PutToTempStorage(PopulatedTS, StorageAddress);
	
EndProcedure

// The procedure fills in the tabular part of the document from the register
// Parameters:
//  Parameters  - Structure - Settings to fill in:
//  	* PopulatedTS - ValueTable -
//  StorageAddress - String - Address of the temporary storage where the task result will be placed.
//
Procedure FillInReplacementDocument(Val Parameters, Val StorageAddress) Export
	
	If Not Parameters.Property("FillInForReplacement") Then
		Return;
	EndIf; 
	
	PeriodColumnName = "DateOfReceipt";
	
	TimeIntervals = Parameters.TimeIntervals;
	FoundPeriodStrings = TimeIntervals.FindRows(New Structure("Active_", True));
	TotalPeriods = FoundPeriodStrings.Count();
	If Parameters.CrossTable And TotalPeriods = 0 Then 
		
		PutToTempStorage(New ValueTable, StorageAddress);
		Return;
		
	EndIf;
	
	Parameters.Insert("TimeIntervals", TimeIntervals); 
	
	PopulatedTS = Parameters.PopulatedTS;
	PeriodColumn = PopulatedTS.Columns[PeriodColumnName]; // ValueTableColumn - 
	PeriodColumn.Name = "CompositionPeriod";
	
	Result = Planning.FillInForReplacement(Parameters);
	
	If Result.Columns.Find("CompositionPeriod") = Undefined Then
		Result.Columns.Add("CompositionPeriod", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date))
	EndIf; 
	
	Result.Columns["CompositionPeriod"].Name = PeriodColumnName;
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Department)
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Scenario)
	|	AND ValueAllowed(PlanProfile)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Status AS Status,
	|	DocumentData.Scenario AS Scenario,
	|	DocumentData.PlanProfile AS PlanProfile,
	|	DocumentData.Substitutional AS Substitutional,
	|	DocumentData.Department AS Department,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Warehouse AS Warehouse,
	|	DocumentData.Partner AS Partner,
	|	CASE
	|		WHEN DocumentData.Scenario.CreatePurchasePlanByAmount
	|			THEN DocumentData.Currency
	|		ELSE DocumentData.BudgetingScenario.Currency
	|	END AS Currency,
	|	DocumentData.BudgetingScenario AS BudgetingScenario,
	|	DocumentData.BeginOfPeriod AS BeginOfPeriod,
	|	DocumentData.PeriodEnding AS PeriodEnding,
	|	DocumentData.Purpose AS Purpose,
	|	DocumentData.PlanProfile.FillInAssignmentInTabularForm AS FillInAssignmentInTabularForm
	|FROM
	|	Document.PurchasePlan AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdditionalAttributes.LineNumber,
	|	AdditionalAttributes.Value
	|FROM
	|	Document.PurchasePlan.AdditionalAttributes AS AdditionalAttributes
	|WHERE
	|	AdditionalAttributes.Ref = &Ref
	|";
	
	QueryResults = Query.ExecuteBatch();  
	Attributes = QueryResults[0].Select();
	Attributes.Next();
	
	Query.SetParameter("BeginOfPeriod",          Attributes.BeginOfPeriod);
	Query.SetParameter("PeriodEnding",       Attributes.PeriodEnding);
	Query.SetParameter("Scenario",               Attributes.Scenario);
	Query.SetParameter("PlanProfile",               Attributes.PlanProfile);
	Query.SetParameter("Substitutional",             Attributes.Substitutional);
	Query.SetParameter("Status",                 Attributes.Status);
	Query.SetParameter("Department",          Attributes.Department);
	Query.SetParameter("Organization",            Attributes.Organization);
	Query.SetParameter("Partner",                Attributes.Partner);
	Query.SetParameter("Purpose",             Attributes.Purpose);
	Query.SetParameter("FillInAssignmentInTabularForm", Attributes.FillInAssignmentInTabularForm);
	Query.SetParameter("Date",                                  Attributes.Date);
	Query.SetParameter("Currency",                                Attributes.Currency);
	Query.SetParameter("BudgetingScenario",                Attributes.BudgetingScenario);
	Query.SetParameter("ManagementAccountingCurrency",            Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("LocalAccountingCurrency",        SettingsValueCached.DefaultBaseCurrency());
	
	SelectionDetailRecords = QueryResults[1].Select();
	While SelectionDetailRecords.Next() Do
		If Not ValueIsFilled(SelectionDetailRecords.Value) Then
			Continue;
		EndIf;
		Query.SetParameter("AdditionalAttribute"+Format(SelectionDetailRecords.LineNumber, "NG=0"), SelectionDetailRecords.Value);
	EndDo;
EndProcedure

Function QueryTextTablePurchasePlans(Query, QueryTexts, Registers)
	
	RegisterName = "PurchasePlans";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.Ref AS PurchasePlan,
	|	&Status AS Status,
	|	CASE
	|		WHEN GoodsTable.DateOfReceipt = DATETIME(1, 1, 1)
	|			THEN &BeginOfPeriod
	|		ELSE GoodsTable.DateOfReceipt
	|	END AS Period,
	|	CASE
	|		WHEN GoodsTable.OrderDate = DATETIME(1, 1, 1)
	|			THEN CASE
	|					WHEN GoodsTable.DateOfReceipt = DATETIME(1, 1, 1)
	|						THEN &BeginOfPeriod
	|					ELSE GoodsTable.DateOfReceipt
	|				END
	|		ELSE GoodsTable.OrderDate
	|	END AS OrderDate,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE GoodsTable.Purpose
	|	END AS Purpose,
	|	&Department AS Department,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|				OR CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE GoodsTable.Warehouse
	|	END AS Warehouse,
	|	&Scenario AS Scenario,
	|	&PlanProfile AS PlanProfile,
	|	GoodsTable.Partner AS Partner,
	|	GoodsTable.Terms AS Terms,
	|	CASE
	|		WHEN GoodsTable.Substituted
	|			THEN 0
	|		ELSE GoodsTable.Count
	|	END AS Count,
	|	CASE
	|		WHEN &Status = VALUE(Enum.PlanStatuses.Upholded)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END AS ToOrder,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.VATAmount AS VATAmount,
	|	CASE
	|		WHEN GoodsTable.DemandRangeIsSpecified
	|			THEN 1
	|		ELSE 0
	|	END AS DemandRangeIsSpecified,
	|	GoodsTable.RangeOfDemandFrom    AS RangeOfDemandFrom,
	|	GoodsTable.RangeOfDemandTo    AS RangeOfDemandTo
	|FROM
	|	Document.PurchasePlan.Goods AS GoodsTable
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON GoodsTable.Products = CatProducts.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.Canceled
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND (NOT GoodsTable.Substituted
	|				AND &Status <> VALUE(Enum.PlanStatuses.Upholded)
	|			OR NOT GoodsTable.SubstitutedToOrder
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashFlowPlansVendors(Query, QueryTexts, Registers)
	
	RegisterName = "CashFlowPlansVendors";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|	&Status AS Status,
	|	DocumentTable.PaymentDate AS Period,
	|	&Scenario AS Scenario,
	|	&Organization AS Organization,
	|	&Partner AS Partner,
	|	DocumentTable.Ref AS Plan,
	|	DocumentTable.PaymentAmount AS Sum,
	|	CASE
	|		WHEN DocumentTable.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation)
	|			OR DocumentTable.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt)
	|			THEN DocumentTable.PaymentAmount
	|		ELSE 0
	|	END AS PrepaymentAmountMan,
	|	CASE
	|		WHEN DocumentTable.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.CreditAfterReceipt)
	|			OR DocumentTable.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment)
	|			THEN DocumentTable.PaymentAmount
	|		ELSE 0
	|	END AS PostpaymentAmount,
	|	DocumentTable.VATAmount AS VATAmount
	|FROM
	|	Document.PurchasePlan.CashFlowPlan AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND NOT DocumentTable.Substituted
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	
	FullDocumentName = "Document.PurchasePlan"; 
	ParameterValues = New Structure;
	
	RedefiningParameterCalculation = New Structure;
		
	If RegisterName = "PurchasePlans" Then
	
		QueryText = QueryTextTablePurchasePlans(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
				
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(QueryText,
																								FullDocumentName,
																								SynonymForDocumentTable,
																								RedefiningParameterCalculation);

	Return Result;

EndFunction

// Generates a request for calculating substituted and replacement plans
// 
// Parameters:
//  Parameters - Structure - Values of additional details.
// 
// Returns:
//  Query
Function RequestReplacementAndReplacementPlans(Parameters) Export

	Query = New Query;
	Query.Text = 
	"SELECT
	|	ProcurementPlanSubstitute.Ref AS ReplacementPlan_3,
	|	CASE
	|		WHEN &BeginOfPeriod > ProcurementPlanSubstitute.BeginOfPeriod
	|			THEN &BeginOfPeriod
	|		ELSE ProcurementPlanSubstitute.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < ProcurementPlanSubstitute.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE ProcurementPlanSubstitute.PeriodEnding
	|	END AS PeriodEnding,
	|	ProcurementPlanSubstitute.Status AS Status
	|FROM
	|	Document.PurchasePlan AS ProcurementPlanSubstitute
	|WHERE
	|	ProcurementPlanSubstitute.PeriodEnding >= &BeginOfPeriod
	|	AND ProcurementPlanSubstitute.BeginOfPeriod <= &PeriodEnding
	|	AND ProcurementPlanSubstitute.Ref <> &Ref
	|	AND ProcurementPlanSubstitute.Posted
	|	AND ProcurementPlanSubstitute.PlanProfile = &PlanProfile
	|	AND (ProcurementPlanSubstitute.Status.Order >= &StatusIndex
	|			OR ProcurementPlanSubstitute.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND ProcurementPlanSubstitute.Date > &Date
	|	AND ProcurementPlanSubstitute.Department = &Department
	|	AND ProcurementPlanSubstitute.Organization = &Organization
	|	AND ProcurementPlanSubstitute.Partner = &Partner
	|	AND ProcurementPlanSubstitute.Terms = &Terms
	|	AND ProcurementPlanSubstitute.Warehouse = &Warehouse
	|	AND ProcurementPlanSubstitute.Purpose = &Purpose
	|
	|ORDER BY
	|	BeginOfPeriod,
	|	Status
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProcurementPlanSubstituted.Ref AS SubstitutedPlan,
	|	CASE
	|		WHEN &BeginOfPeriod > ProcurementPlanSubstituted.BeginOfPeriod
	|			THEN &BeginOfPeriod
	|		ELSE ProcurementPlanSubstituted.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < ProcurementPlanSubstituted.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE ProcurementPlanSubstituted.PeriodEnding
	|	END AS PeriodEnding,
	|	ProcurementPlanSubstituted.Status AS Status
	|FROM
	|	Document.PurchasePlan AS ProcurementPlanSubstituted
	|WHERE
	|	ProcurementPlanSubstituted.PeriodEnding >= &BeginOfPeriod
	|	AND ProcurementPlanSubstituted.BeginOfPeriod <= &PeriodEnding
	|	AND ProcurementPlanSubstituted.Ref <> &Ref
	|	AND ProcurementPlanSubstituted.Posted
	|	AND ProcurementPlanSubstituted.PlanProfile = &PlanProfile
	|	AND (ProcurementPlanSubstituted.Status.Order <= &StatusIndex
	|			OR ProcurementPlanSubstituted.Status = VALUE(Enum.PlanStatuses.Upholded)
	|				AND &Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation))
	|	AND ProcurementPlanSubstituted.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND ProcurementPlanSubstituted.Date < &Date
	|	AND ProcurementPlanSubstituted.Department = &Department
	|	AND ProcurementPlanSubstituted.Organization = &Organization
	|	AND ProcurementPlanSubstituted.Partner = &Partner
	|	AND ProcurementPlanSubstituted.Terms = &Terms
	|	AND ProcurementPlanSubstituted.Warehouse = &Warehouse
	|	AND ProcurementPlanSubstituted.Purpose = &Purpose
	|
	|ORDER BY
	|	BeginOfPeriod,
	|	Status";
	
	Query.SetParameter("Ref", Parameters.Ref);
	Query.SetParameter("PlanProfile", Parameters.PlanProfile);
	Query.SetParameter("StatusIndex", Enums.PlanStatuses.IndexOf(Parameters.Status));
	Query.SetParameter("Status", Parameters.Status);
	Query.SetParameter("Date", Parameters.Date);
	Query.SetParameter("Partner", Parameters.Partner);
	Query.SetParameter("Department", Parameters.Department);
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("Terms", Parameters.Terms);
	Query.SetParameter("Warehouse", Parameters.Warehouse);
	Query.SetParameter("Purpose", Parameters.Purpose);
	Query.SetParameter("BeginOfPeriod", Parameters.BeginOfPeriod);
	Query.SetParameter("PeriodEnding", Parameters.PeriodEnding);
	Query.SetParameter("Periodicity", Parameters.Periodicity);
		
	Return Query;
	
EndFunction

// Generates a request to fill in the document
// 
// Parameters:
//  Parameters - Structure - Values of additional details.
// 
// Returns:
//  Query - Replacement request
Function ReplacementRequest(Parameters) Export

	Query = New Query;
	Query.Text =
		"SELECT
		|	PurchasePlansTurnovers.Period AS CompositionPeriod,
		|	PurchasePlansTurnovers.Scenario,
		|	PurchasePlansTurnovers.Status,
		|	PurchasePlansTurnovers.Products,
		|	PurchasePlansTurnovers.Characteristic,
		|	PurchasePlansTurnovers.Department,
		|	PurchasePlansTurnovers.Organization,
		|	PurchasePlansTurnovers.Warehouse,
		|	PurchasePlansTurnovers.Partner,
		|	PurchasePlansTurnovers.Purpose,
		|	PurchasePlansTurnovers.Terms,
		|	PurchasePlansTurnovers.CountTurnover AS NumberOfPackages,
		|	PurchasePlansTurnovers.SumTurnover AS Sum
		|FROM
		|	AccumulationRegister.PurchasePlans.Turnovers(
		|			&BeginOfPeriod,
		|			&EndOfPeriod,
		|			Record,
		|			Scenario = &Scenario
		|				AND PlanProfile = &PlanProfile
		|				AND &QueryTextFilterDepartment
		|				AND &QueryTextFilterOrganization
		|				AND &QueryTextFilterWarehouse
		|				AND &QueryTextFilterTerms
		|				AND &QueryTextFilterPartner
		|				AND (&FillInAssignmentInTabularForm OR Purpose = &Purpose)
		|				AND Status IN (&Statuses)) AS PurchasePlansTurnovers";
		
	Query.SetParameter("EndOfPeriod",   Parameters.OffsetPeriodEnd);
	Query.SetParameter("BeginOfPeriod",  Parameters.OffsetPeriodStart);
	Query.SetParameter("Partner",        Parameters.Partner);
	Query.SetParameter("Department",  Parameters.Department);
	Query.SetParameter("Organization",    Parameters.Organization);
	Query.SetParameter("Warehouse",          Parameters.Warehouse);
	Query.SetParameter("Terms",     Parameters.Terms);
	Query.SetParameter("Statuses",        Parameters.Statuses);
	Query.SetParameter("Scenario",       Parameters.Scenario);
	Query.SetParameter("PlanProfile",       Parameters.PlanProfile);
	Query.SetParameter("FillInAssignmentInTabularForm", Parameters.FillInAssignmentInTabularForm);
	Query.SetParameter("Purpose",     Parameters.Purpose);
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterPartner",
		?(ValueIsFilled(Parameters.Partner),"Partner = &Partner","True"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterDepartment",
		?(ValueIsFilled(Parameters.Department),"Department = &Department","True"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterOrganization",
		?(ValueIsFilled(Parameters.Organization),"Organization = &Organization","True"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterWarehouse",
		?(ValueIsFilled(Parameters.Warehouse),"Warehouse = &Warehouse","True"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterTerms",
		?(ValueIsFilled(Parameters.Terms),"Terms = &Terms","True"));
	
	Return Query;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	
	// The needs for goods in stock in the header.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "SecuringWarehouseOrdersInHeader");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse AND Object.Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	
	// Needs for goods in stock in pm.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "ProvisionOfOrdersWarehouseVHF");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouseInTabularForm AND Object.Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Goods.Warehouse";
	
	// Needs for goods in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.Goods.Purpose", "SecuringOrdersAllWarehouses");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse = FALSE AND Object.PlanProfile.FillInWarehouseInTabularForm = FALSE AND Object.Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	
	// The needs for work in the recipient department.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.Goods.Purpose", "FulfillOrdersWithWorks");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInBusinessUnit AND Object.Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.Department";
	
	// The needs for goods in stock in the header (by period).
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.GoodsByPeriod.Purpose", "SecuringOrdersForWarehousePeriodsInHeader");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse AND Object.GoodsByPeriod.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.GoodsByPeriod.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.GoodsByPeriod.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	
	// Needs for goods in stock in pm (by period).
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.GoodsByPeriod.Purpose", "ProvisionOfOrdersForPeriodsWarehouseWH");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouseInTabularForm AND Object.GoodsByPeriod.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.GoodsByPeriod.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.GoodsByPeriod.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.GoodsByPeriod.Warehouse";
	
	// Needs for goods in all warehouses (by period).
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.GoodsByPeriod.Purpose", "SecuringOrdersForAllWarehousesByPeriod");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInWarehouse = FALSE AND Object.PlanProfile.FillInWarehouseInTabularForm = FALSE AND Object.GoodsByPeriod.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.GoodsByPeriod.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.GoodsByPeriod.Characteristic";
	
	// Requirements for work in the recipient unit (by period).
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.GoodsByPeriod.Purpose", "ProvisionOfOrdersWithWorksByPeriods");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.PlanProfile.FillInBusinessUnit AND Object.GoodsByPeriod.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.GoodsByPeriod.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.GoodsByPeriod.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.Department";
	
	// All assignments for the Assignment field in the document header.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.Purpose");
	
	Return FormTemplate;
	
EndFunction

#EndRegion

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Procurement plan
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PurchasePlan";
	PrintCommand.Presentation = NStr("vi = 'Kế hoạch mua hàng';
									|ru = 'План закупок';
									|en = 'Purchase plan'; fa = 'برنامه خرید';
									|it = 'Piano di acquisti';
									|pl = 'Plan zakupów';
									|tr = 'Satın alma planı'");
	PrintCommand.CheckPostingBeforePrint = True;

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PurchasePlan") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"PurchasePlan",
			NStr("vi = 'Kế hoạch mua hàng';
				|ru = 'План закупок';
				|en = 'Purchase plan'; fa = 'برنامه خرید';
				|it = 'Piano di acquisti';
				|pl = 'Plan zakupów';
				|tr = 'Satın alma planı'"),
			CreatePrintedFormOfPlan(ObjectsArray, PrintObjects, PrintParameters));
	EndIf;
		
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function CreatePrintedFormOfPlan(ObjectsArray, PrintObjects, PrintParameters)
	
	SetPrivilegedMode(True);
	
	If PrintParameters <> Undefined And PrintParameters.Property("CrossTable") Then
		DefaultCrossTable = PrintParameters.CrossTable = True;
		DefaultTable = PrintParameters.CrossTable = False;
	Else
		DefaultCrossTable = False;
		DefaultTable = False;
	EndIf; 
	
	DisplayHeader = True;
	If PrintParameters <> Undefined And PrintParameters.Property("DisplayHeader") Then
		DisplayHeader = PrintParameters.DisplayHeader;
	EndIf;
	
	OutputScript 		= True;
	DisplayPeriodStatus	= True;
	OutputDivision	= True;
	OutputCompany		= True;
	WithdrawPartner 		= True;
	OutputAgreement 		= True;
	WithdrawWarehouse 			= True;
	WithdrawVHFPartner 	= True;
	WithdrawVHFAgreement 	= True;
	DisplayVHFWarehouse 		= True;
	
	If PrintParameters <> Undefined And Not PrintParameters.Property("OutputScript", OutputScript) Then
		OutputScript 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("DisplayPeriodStatus", DisplayPeriodStatus) Then
		DisplayPeriodStatus	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("OutputDivision", OutputDivision) Then
		OutputDivision 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("OutputCompany", OutputCompany) Then
		OutputCompany 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("WithdrawPartner", WithdrawPartner) Then
		WithdrawPartner 		= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("OutputAgreement", OutputAgreement) Then
		OutputAgreement 		= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("WithdrawWarehouse", WithdrawWarehouse) Then
		WithdrawWarehouse 			= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("WithdrawVHFPartner", WithdrawVHFPartner) Then
		WithdrawVHFPartner 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("WithdrawVHFAgreement", WithdrawVHFAgreement) Then
		WithdrawVHFAgreement 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("DisplayVHFWarehouse", DisplayVHFWarehouse) Then
		DisplayVHFWarehouse 		= True;
	EndIf;
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
		
	Query = New Query(
	"SELECT
	|	DocumentTable.Ref                         AS Ref,
	|	DocumentTable.Number                          AS Number,
	|	DocumentTable.Date                           AS Date,
	|	DocumentTable.EmployeeResponsible                  AS EmployeeResponsible,
	|	DocumentTable.Status                         AS Status,
	|	DocumentTable.Periodicity                  AS Periodicity,
	|	DocumentTable.BeginOfPeriod                  AS BeginOfPeriod,
	|	DocumentTable.PeriodEnding               AS PeriodEnding,
	|	DocumentTable.Scenario                       AS Scenario,
	|	DocumentTable.PlanProfile                       AS PlanProfile,
	|	CASE
	|		WHEN &DefaultCrossTable
	|				OR DocumentTable.CrossTable
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                           AS CrossTable,
	|	DocumentTable.FilledAutomatically         AS FilledAutomatically,
	|	CatPlanProfiles.FillInBusinessUnit            AS FillInBusinessUnit,
	|	CatPlanProfiles.FillInCompany              AS FillInCompany,
	|	CatPlanProfiles.FillInPartner                 AS FillInPartner,
	|	CatPlanProfiles.FillInTermsOfSales               AS FillInTermsOfSales,
	|	CatPlanProfiles.FillInManager                AS FillInManager,
	|	CatPlanProfiles.FillInWarehouse                    AS FillInWarehouse,
	|	CatPlanProfiles.FillInStoreFormat           AS FillInStoreFormat,
	|	CatPlanProfiles.FillInPartnerInTabularForm              AS FillInPartnerInTabularForm,
	|	CatPlanProfiles.FillInAgreementInTabularForm            AS FillInAgreementInTabularForm,
	|	CatPlanProfiles.FillInWarehouseInTabularForm                 AS FillInWarehouseInTabularForm,
	|	PlanningScenarios.ShowNumberOfPeriod     AS ShowNumberOfPeriod,
	|	Users.Individual                     AS ResponsibleIndividual,
	|	DocumentTable.Currency                         AS Currency,
	|	DocumentTable.PlanByAmount             AS PlanByAmount,
	|	DocumentTable.Partner                        AS Partner,
	|	DocumentTable.Department                  AS Department,
	|	DocumentTable.Organization                    AS Organization,
	|	DocumentTable.Terms                     AS Terms,
	|	DocumentTable.Warehouse                          AS Warehouse,
	|	DocumentTable.Purpose                     AS Purpose,
	|	PlanningScenarios.PlanningByAssignments  AS PlanningByAssignments,
	|	CatPlanProfiles.FillInAssignmentInTabularForm            AS FillInAssignmentInTabularForm
	|FROM
	|	Document.PurchasePlan AS DocumentTable
	|		LEFT JOIN Catalog.SalesOperationsPlanningScenarios AS PlanningScenarios
	|		ON DocumentTable.Scenario = PlanningScenarios.Ref
	|		LEFT JOIN Catalog.PlanProfiles AS CatPlanProfiles
	|		ON DocumentTable.PlanProfile = CatPlanProfiles.Ref
	|		LEFT JOIN Catalog.Users AS Users
	|		ON DocumentTable.EmployeeResponsible = Users.Ref
	|WHERE
	|	DocumentTable.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref                            AS Ref,
	|	GoodsTable.Products                      AS Products,
	|	GoodsTable.Products.DescriptionFull   AS ProductNameFull_,
	|	GoodsTable.Products.Code                  AS Code,
	|	GoodsTable.Products.SKU              AS SKU,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure
	|		ELSE GoodsTable.Package
	|	END                                           AS UnitOfMeasure,
	|	GoodsTable.Characteristic.DescriptionFull AS CharacteristicFullName,
	|	GoodsTable.Characteristic                    AS Characteristic,
	|	GoodsTable.Package                          AS Package,
	|	GoodsTable.LineNumber                       AS LineNumber,
	|	GoodsTable.DateOfReceipt                   AS PeriodDate_,
	|	GoodsTable.OrderDate                        AS OrderDate,
	|	GoodsTable.NumberOfPackages                AS Count,
	|	GoodsTable.Comment                       AS Comment,
	|	GoodsTable.Price                              AS Price,
	|	GoodsTable.Sum                             AS Sum,
	|	GoodsTable.Warehouse                             AS Warehouse,
	|	GoodsTable.Partner                           AS Partner,
	|	GoodsTable.Terms                        AS Terms,
	|	GoodsTable.Purpose.Description           AS PurposeName,
	|	GoodsTable.Purpose                        AS Purpose
	|FROM
	|	Document.PurchasePlan.Goods AS GoodsTable
	|WHERE
	|	(&DefaultTable
	|			OR NOT GoodsTable.Ref.CrossTable)
	|	AND GoodsTable.Ref IN(&DocumentsArray)
	|	AND NOT GoodsTable.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	NestedQuery.Ref,
	|	NestedQuery.Products,
	|	NestedQuery.Products.DescriptionFull,
	|	NestedQuery.Products.Code,
	|	NestedQuery.Products.SKU,
	|	CASE
	|		WHEN NestedQuery.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN NestedQuery.Products.UnitOfMeasure
	|		ELSE NestedQuery.Package
	|	END,
	|	NestedQuery.Characteristic.DescriptionFull,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Package,
	|	MIN(NestedQuery.LineNumber),
	|	NestedQuery.PeriodDate_,
	|	NestedQuery.OrderDate,
	|	SUM(NestedQuery.NumberOfPackages),
	|	MAX(NestedQuery.Comment),
	|	NestedQuery.Price,
	|	SUM(NestedQuery.Sum),
	|	NestedQuery.Warehouse,
	|	NestedQuery.Partner,
	|	NestedQuery.Terms,
	|	NestedQuery.Purpose.Description,
	|	NestedQuery.Purpose
	
	|FROM
	|	(SELECT
	|		GoodsTable.Ref AS Ref,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Package AS Package,
	|		CASE DocumentTable.Periodicity
	|			WHEN VALUE(Enum.Periodicity.YEAR)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfReceipt, YEAR)
	|			WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfReceipt, HALFYEAR)
	|			WHEN VALUE(Enum.Periodicity.QUARTER)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfReceipt, QUARTER)
	|			WHEN VALUE(Enum.Periodicity.MONTH)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfReceipt, MONTH)
	|			WHEN VALUE(Enum.Periodicity.TENDAYS)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfReceipt, TENDAYS)
	|			WHEN VALUE(Enum.Periodicity.WEEK)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfReceipt, WEEK)
	|			ELSE GoodsTable.DateOfReceipt
	|		END AS PeriodDate_,
	|		CASE DocumentTable.Periodicity
	|			WHEN VALUE(Enum.Periodicity.YEAR)
	|				THEN BEGINOFPERIOD(GoodsTable.OrderDate, YEAR)
	|			WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|				THEN BEGINOFPERIOD(GoodsTable.OrderDate, HALFYEAR)
	|			WHEN VALUE(Enum.Periodicity.QUARTER)
	|				THEN BEGINOFPERIOD(GoodsTable.OrderDate, QUARTER)
	|			WHEN VALUE(Enum.Periodicity.MONTH)
	|				THEN BEGINOFPERIOD(GoodsTable.OrderDate, MONTH)
	|			WHEN VALUE(Enum.Periodicity.TENDAYS)
	|				THEN BEGINOFPERIOD(GoodsTable.OrderDate, TENDAYS)
	|			WHEN VALUE(Enum.Periodicity.WEEK)
	|				THEN BEGINOFPERIOD(GoodsTable.OrderDate, WEEK)
	|			ELSE GoodsTable.OrderDate
	|		END AS OrderDate,
	|		GoodsTable.LineNumber AS LineNumber,
	|		CASE WHEN GoodsTable.Canceled THEN 0 ELSE GoodsTable.NumberOfPackages END AS NumberOfPackages,
	|		CASE WHEN GoodsTable.Canceled THEN """" ELSE CAST(GoodsTable.Comment AS STRING(1000)) END AS Comment,
	|		CASE WHEN GoodsTable.Canceled THEN 0 ELSE GoodsTable.Price END AS Price,
	|		CASE WHEN GoodsTable.Canceled THEN 0 ELSE GoodsTable.Sum END AS Sum,
	|		GoodsTable.Warehouse                 AS Warehouse,
	|		GoodsTable.Partner               AS Partner,
	|		GoodsTable.Terms            AS Terms,
	|		GoodsTable.Purpose            AS Purpose
	|	FROM
	|		Document.PurchasePlan.Goods AS GoodsTable
	|			INNER JOIN Document.PurchasePlan AS DocumentTable
	|			ON GoodsTable.Ref = DocumentTable.Ref
	|	WHERE
	|		(&DefaultCrossTable
	|				OR GoodsTable.Ref.CrossTable)
	|		AND GoodsTable.Ref IN(&DocumentsArray)
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.Products,
	|	NestedQuery.Products.DescriptionFull,
	|	NestedQuery.Products.Code,
	|	NestedQuery.Products.SKU,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Characteristic.DescriptionFull,
	|	NestedQuery.Purpose,
	|	NestedQuery.Purpose.Description,
	|	NestedQuery.Price,
	|	NestedQuery.Warehouse,
	|	NestedQuery.Partner,
	|	NestedQuery.Terms,
	|	NestedQuery.PeriodDate_,
	|	NestedQuery.OrderDate,
	|	CASE
	|		WHEN NestedQuery.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN NestedQuery.Products.UnitOfMeasure
	|		ELSE NestedQuery.Package
	|	END,
	|	NestedQuery.Package
	|
	|ORDER BY
	|	Ref,
	|	LineNumber,
	|	ProductNameFull_,
	|	CharacteristicFullName,
	|	PurposeName,
	|	Partner,
	|	Terms,
	|	Warehouse,
	|	UnitOfMeasure,
	|	PeriodDate_
	|TOTALS BY
	|	Ref");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_PurchasePlan_PurchasePlan";
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	Query.SetParameter("DefaultCrossTable", DefaultCrossTable);
	Query.SetParameter("DefaultTable", DefaultTable);
	
	ResultsArray 		= Query.ExecuteBatch(); 
	PrintData			= ResultsArray[0].Select();
	SelectionByDocuments 	= ResultsArray[1].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	ThereAreDocumentsWithAmounts = False;
	ThereAreCrossTables = False;
	BeginningOfHeader = 0;
	EndOfHeader = 0;
	NumberWidth = 0;
	EndOfIssue = 0;
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	
	While PrintData.Next() Do
		
		PlanByAmount = PrintData.PlanByAmount;
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		ProductSelection_1 = SelectionByDocuments.Select();
		
		CrossTable = PrintData.CrossTable;
		
		If CrossTable Then
			PeriodsTable = Planning.PeriodTableTemplate();
			Planning.FillInPeriodTable(PeriodsTable, 
				PrintData.Periodicity, 
				PrintData.BeginOfPeriod, 
				PrintData.PeriodEnding, 
				?(DisplayHeader, PrintData.ShowNumberOfPeriod, False));
			CrossTable = PeriodsTable.Count() > 1 Or Not DisplayHeader;
		EndIf;
		
		// The layout must be obtained for each document, because the column sizes change dynamically.
		Template = PrintManagement.PrintFormTemplate("Document.PurchasePlan.PF_MXL_PurchasePlan");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the plan
		If DisplayHeader Then
			
			TemplateArea = Template.GetArea("Title");
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
			
			TitleText = TMCommonUseClientServer.GenerateDocumentTitle(PrintData, NStr("vi = 'Kế hoạch mua hàng';
																						|ru = 'План закупок';
																						|en = 'Purchase plan'; fa = 'برنامه خرید';
																						|it = 'Piano di acquisti';
																						|pl = 'Plan zakupów';
																						|tr = 'Satın alma planı'", Common.DefaultLanguageCode()));
			TemplateArea.Parameters.TitleText = TitleText;
			SpreadsheetDocument.Put(TemplateArea);
			
			If OutputScript Then
				TemplateArea                                  = Template.GetArea("Scenario");
				ScriptPresentation                          = String(PrintData.Scenario) + ", "+ String(PrintData.Periodicity);
				If PlanByAmount Then
					ScriptPresentation                      = ScriptPresentation + ", " + String(PrintData.Currency);
				EndIf; 
				TemplateArea.Parameters.ScriptPresentation  = ScriptPresentation;
				TemplateArea.Parameters.Scenario               = PrintData.Scenario;
				PresentationOfPlanView                         = String(PrintData.PlanProfile);
				TemplateArea.Parameters.PresentationOfPlanView = PresentationOfPlanView;
				TemplateArea.Parameters.PlanProfile               = PrintData.PlanProfile;
				SpreadsheetDocument.Put(TemplateArea);
			EndIf;
			
			If DisplayPeriodStatus Then
				TemplateArea                                = Template.GetArea("PeriodStatus");
				PeriodPresentation                         = NStr("vi = 'Kỳ từ %1 đến %2';
																	|ru = 'Период с %1 по %2';
																	|en = 'Period from %1 to %2'; fa = 'Period from %1 to %2';
																	|it = 'Periodo da %1 a %2';
																	|pl = 'Okres od %1 do %2';
																	|tr = '%1 tarihinden %2 tarihine kadar dönem'", Common.DefaultLanguageCode());
				PeriodPresentation                         = StringFunctionsClientServer.SubstituteParametersToString(PeriodPresentation,
					Format(PrintData.BeginOfPeriod, "DLF=D"), 
					Format(PrintData.PeriodEnding, "DLF=D"));
				TemplateArea.Parameters.PeriodPresentation = PeriodPresentation;
				TemplateArea.Parameters.Status = String(PrintData.Status);
				SpreadsheetDocument.Put(TemplateArea);
			EndIf;
			
			If PrintData.FillInBusinessUnit And OutputDivision Then
				TemplateArea                                       = Template.GetArea("Department");
				DivisionRepresentation                          = String(PrintData.Department);
				TemplateArea.Parameters.DivisionRepresentation  = DivisionRepresentation;
				TemplateArea.Parameters.Department               = PrintData.Department;
				SpreadsheetDocument.Put(TemplateArea);
			EndIf;
			
			If PrintData.FillInCompany And OutputCompany Then
				TemplateArea                                       = Template.GetArea("Organization");
				RepresentationOfTheOrganization                            = String(PrintData.Organization);
				TemplateArea.Parameters.RepresentationOfTheOrganization    = RepresentationOfTheOrganization;
				TemplateArea.Parameters.Organization                 = PrintData.Organization;
				SpreadsheetDocument.Put(TemplateArea);
			EndIf;
			
			If PrintData.FillInPartner And WithdrawPartner Then
				TemplateArea                                 = Template.GetArea("Partner");
				PartnerView                          = String(PrintData.Partner);
				TemplateArea.Parameters.PartnerPresentation_ = PartnerView;
				TemplateArea.Parameters.Partner               = PrintData.Partner;
				SpreadsheetDocument.Put(TemplateArea);
			EndIf; 
			
			If PrintData.FillInTermsOfSales And OutputAgreement Then
				TemplateArea                                   = Template.GetArea("Terms");
				PresentationOfAgreement                         = String(PrintData.Terms);
				TemplateArea.Parameters.PresentationOfAgreement = PresentationOfAgreement;
				TemplateArea.Parameters.Terms              = PrintData.Terms;
				SpreadsheetDocument.Put(TemplateArea);
			EndIf;
			
			If PrintData.FillInWarehouse And WithdrawWarehouse Then
				TemplateArea                               = Template.GetArea("Warehouse");
				WarehousePresentation_                         = String(PrintData.Warehouse);
				TemplateArea.Parameters.WarehousePresentation_ = WarehousePresentation_;
				TemplateArea.Parameters.Warehouse               = PrintData.Warehouse;
				SpreadsheetDocument.Put(TemplateArea);
			EndIf;
			
			If PrintData.PlanningByAssignments
				And Not PrintData.FillInAssignmentInTabularForm Then
				TemplateArea                                   = Template.GetArea("Purpose");
				PresentationPurpose                         = String(PrintData.Purpose);
				TemplateArea.Parameters.PresentationPurpose = PresentationPurpose;
				TemplateArea.Parameters.Purpose              = PrintData.Purpose;
				SpreadsheetDocument.Put(TemplateArea);
			EndIf;
			
		EndIf;
	
		// Output the title of the Products table
		Add_Fields = New Array; // Array of See Planning.StructureOfAdditionalField
		If PrintData.PlanningByAssignments
			And PrintData.FillInAssignmentInTabularForm Then
			StructureOfAdditionalField = Planning.StructureOfAdditionalField();
			StructureOfAdditionalField.Insert("Title", NStr("vi = 'Ấn định';
															|ru = 'Назначение';
															|en = 'Assignment'; fa = 'تخصیص';
															|it = 'Destinazione';
															|pl = 'Przeznaczenie';
															|tr = 'Atama'", Common.DefaultLanguageCode()));
			StructureOfAdditionalField.Insert("ValueColumn_", "Purpose");
			Add_Fields.Add(StructureOfAdditionalField);
		EndIf;
		If PrintData.FillInPartnerInTabularForm Then
			StructureOfAdditionalField = Planning.StructureOfAdditionalField();
			StructureOfAdditionalField.Insert("Title", NStr("vi = 'Nhà cung cấp';
															|ru = 'Поставщик';
															|en = 'Vendor'; fa = 'تأمین‌کننده';
															|it = 'Fornitore';
															|pl = 'Dostawca';
															|tr = 'Tedarikçi'", Common.DefaultLanguageCode()));
			StructureOfAdditionalField.Insert("ValueColumn_", "Partner");
			Add_Fields.Add(StructureOfAdditionalField);
		EndIf;
		If PrintData.FillInAgreementInTabularForm Then
			StructureOfAdditionalField = Planning.StructureOfAdditionalField();
			StructureOfAdditionalField.Insert("Title", NStr("vi = 'Thỏa thuận';
															|ru = 'Соглашение';
															|en = 'Agreement'; fa = 'توافق‌نامه';
															|it = 'Accordo';
															|pl = 'Porozumienie:';
															|tr = 'Anlaşma'", Common.DefaultLanguageCode()));
			StructureOfAdditionalField.Insert("ValueColumn_", "Terms");
			Add_Fields.Add(StructureOfAdditionalField);
		EndIf;
		If PrintData.FillInWarehouseInTabularForm Then
			StructureOfAdditionalField = Planning.StructureOfAdditionalField();
			StructureOfAdditionalField.Insert("Title", NStr("vi = 'Kho bãi';
															|ru = 'Склад';
															|en = 'Warehouse'; fa = 'Warehouse';
															|it = 'Magazzino';
															|pl = 'Magazyn';
															|tr = 'Ambar'", Common.DefaultLanguageCode()));
			StructureOfAdditionalField.Insert("ValueColumn_", "Warehouse");
			Add_Fields.Add(StructureOfAdditionalField);
		EndIf;
		
		OwnGoods = ?(Not (DisplayHeader Or UseItemVariants), "ProductWithoutCharacteristics", "OwnGoods");
		ProductAddField = ?(PlanByAmount, "ProductAmountSurcharge", "ProductAddField");
		NumberOfCrossEndings = ?(PlanByAmount, "NumberAmountCrossEnd", "NumberOfCrossEndings");
		Count = "Count";
		If PlanByAmount And CrossTable Then
			Count = "NumberSumCross"
		ElsIf PlanByAmount And Not CrossTable Then
			Count = "QuantityAmount"
		ElsIf Not PlanByAmount And CrossTable Then
			Count = "NumberOfCrosses"
		EndIf;
		// Calculation of the width of the product column
		ProductColumnWidth = Template.Area(OwnGoods).ColumnWidth * 2; // The area contains 2 columns - item and characteristics
		
		If PlanByAmount Then
			ProductColumnWidth = ProductColumnWidth - 12;
		EndIf; 
		If Not OutputCodes Then
			ProductColumnWidth = ProductColumnWidth + Template.Area("ColumnOfCodes").ColumnWidth;
		EndIf; 
		If Add_Fields.Count() > 0 Then
			ProductColumnWidth = ProductColumnWidth - Template.Area(ProductAddField + Format(Add_Fields.Count(), "NFD=0; NG=0")).ColumnWidth * Add_Fields.Count();
		EndIf; 
		If DisplayHeader Or UseItemVariants Then
			ProductColumnWidth = ProductColumnWidth / 2;
		EndIf; 
		Template.Area(OwnGoods).ColumnWidth = ProductColumnWidth;
		
		TextOnFirstPage = ?(PlanByAmount, 1, 2);
		PeriodsOnPage = ?(PlanByAmount, 3, 7);
		
		RoomArea                   = Template.GetArea("TableHeader|LineNumber");
		UIArea                       = Template.GetArea("TableHeader|UniqueIdentifiers");
		AreaCodes                    = Template.GetArea("TableHeader|ColumnOfCodes");
		ProductArea                    = Template.GetArea(?(DisplayHeader,"TableHeader","HeaderOfNHTable") + "|" + OwnGoods);
		DataArea                   = Template.GetArea(?(DisplayHeader Or CrossTable,"TableHeader","HeaderOfNHTable") + "|" + Count);
		DataAreaCrossEnd     = Template.GetArea("TableHeader|" + NumberOfCrossEndings);
		AreaDatePeriod               = Template.GetArea("TableHeader|DatePeriod");
		AreaOrderDate               = Template.GetArea("TableHeader|OrderDate");
		AreaCrossUnitOfMeasurement    = Template.GetArea("TableHeader|CrossUnitOfMeasurement");
		If Add_Fields.Count() > 0 Then
			ProductFieldArea         = Template.GetArea("TableHeader|" + ProductAddField + Format(Add_Fields.Count(), "NFD=0; NG=0"));
		EndIf; 
		
		SpreadsheetDocument.Put(RoomArea);
		If Not DisplayHeader Then
			SpreadsheetDocument.Join(UIArea);
		EndIf;
		
		If OutputCodes Then
			AreaCodes.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		
		For Each AdditionalField_ In Add_Fields Do
			ProductFieldArea.Parameters.Title = AdditionalField_.Title;
			SpreadsheetDocument.Join(ProductFieldArea);
		EndDo; 
		
		PageNumber = 1;
		If CrossTable Then
			SpreadsheetDocument.Join(AreaCrossUnitOfMeasurement);
			AmountsOfPeriods = New Structure;
			For Each Period In PeriodsTable Do
				AmountsOfPeriods.Insert("Sum_"+Period.ColumnName, 0);
				IndexOf = PeriodsTable.IndexOf(Period);
				If IndexOf = PeriodsTable.Count()-1 Then
					DataAreaCrossEnd.Parameters.Title = Period.Title;
					SpreadsheetDocument.Join(DataAreaCrossEnd);
				Else
					DataArea.Parameters.Title = Period.Title;
					SpreadsheetDocument.Join(DataArea);
				EndIf;
			EndDo;
		Else
			SpreadsheetDocument.Join(AreaDatePeriod);
			SpreadsheetDocument.Join(AreaOrderDate);
			SpreadsheetDocument.Join(DataArea);
		EndIf; 
		
		BeginningOfHeader = SpreadsheetDocument.TableHeight - RoomArea.TableHeight +1;
		EndOfHeader = SpreadsheetDocument.TableHeight;
		NumberWidth = RoomArea.TableWidth;
		
		RoomArea                   = Template.GetArea("TableRow|LineNumber");
		UIArea                       = Template.GetArea("TableRow|UniqueIdentifiers");
		AreaCodes                    = Template.GetArea("TableRow|ColumnOfCodes");
		ProductArea                    = Template.GetArea("TableRow|" + OwnGoods);
		DataArea                   = Template.GetArea("TableRow|" + Count);
		DataAreaCrossEnd     = Template.GetArea("TableRow|" + NumberOfCrossEndings);
		AreaDatePeriod               = Template.GetArea("TableRow|DatePeriod");
		AreaOrderDate               = Template.GetArea("TableRow|OrderDate");
		AreaCrossUnitOfMeasurement    = Template.GetArea("TableRow|CrossUnitOfMeasurement");
		If Add_Fields.Count() > 0 Then
			ProductFieldArea         = Template.GetArea("TableRow|" + ProductAddField + Format(Add_Fields.Count(), "NFD=0; NG=0") );
		EndIf;
		
		CurrentRow  = New Structure("Products, Characteristic, Purpose, Partner, Terms, Warehouse, UnitOfMeasure");
		Sum          = 0;
		CurrentPeriod  = 0;
		LineNumber    = 0;
	
		// Output the rows of the Goods table
		While ProductSelection_1.Next() Do
			
			IdenticalLines = True;
			If CrossTable Then
				For Each Item In CurrentRow Do
					If ProductSelection_1[Item.Key] <> Item.Value Then
						IdenticalLines = False;
						Break;
					EndIf; 
				EndDo; 
			EndIf;
			
			If Not CrossTable Or CrossTable And Not IdenticalLines Then
				
				// Additional product line formation if there is no data until the end of the period
				If CrossTable And CurrentPeriod <> 0 And CurrentPeriod < PeriodsTable.Count() Then
					While CurrentPeriod < PeriodsTable.Count() Do
						CurrentPeriod = CurrentPeriod + 1;
						If CurrentPeriod < PeriodsTable.Count() Then
							SpreadsheetDocument.Join(Template.GetArea("TableRow|" + Count));
						Else
							SpreadsheetDocument.Join(Template.GetArea("TableRow|" + NumberOfCrossEndings));
						EndIf;
					EndDo;
				EndIf;
		
				FillPropertyValues(CurrentRow, ProductSelection_1);
				CurrentPeriod = 0;
				
				LineNumber = LineNumber + 1;
				
				RoomArea.Parameters.LineNumber = LineNumber;
				SpreadsheetDocument.Put(RoomArea);
				
				If Not DisplayHeader Then
					UIArea.Parameters.UniqueProductIdentifier          = String(ProductSelection_1.Products.UUID());
					UIArea.Parameters.UniqueIdentifierCharacteristic        = String(ProductSelection_1.Characteristic.UUID());
					UIArea.Parameters.UniqueIdentifierPackaging              = String(ProductSelection_1.Package.UUID());
					
					UIArea.Parameters.UniquePartnerID               = String(ProductSelection_1.Partner.UUID());
					UIArea.Parameters.UniqueIdentifierAgreement            = String(ProductSelection_1.Terms.UUID());
					UIArea.Parameters.UniqueWarehouseID                 = String(ProductSelection_1.Warehouse.UUID());
					UIArea.Parameters.UniqueIdentifierPurpose            = String(ProductSelection_1.Purpose.UUID());
					
					SpreadsheetDocument.Join(UIArea);
				EndIf;
				
				If OutputCodes Then
					
					AreaCodes.Parameters.SKU = ProductSelection_1[NameOfCodeColumn];
					SpreadsheetDocument.Join(AreaCodes);
					
				EndIf;
				
				AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
				AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
				
				ProductArea.Parameters.Fill(ProductSelection_1);
				
				ProductArea.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
					ProductSelection_1.ProductNameFull_,
					ProductSelection_1.CharacteristicFullName,
					,
					,
					AdditionalParametersProductPresentation);
				
				SpreadsheetDocument.Join(ProductArea);
				
				For Each AdditionalField_ In Add_Fields Do
					ProductFieldArea.Parameters.Value = ProductSelection_1[AdditionalField_.ValueColumn_];
					SpreadsheetDocument.Join(ProductFieldArea);
				EndDo;
				
				If CrossTable Then
				
					AreaCrossUnitOfMeasurement.Parameters.Fill(ProductSelection_1);
					SpreadsheetDocument.Join(AreaCrossUnitOfMeasurement);
				
				EndIf; 
				
			EndIf;
			
			If CrossTable Then
				
				Period = PeriodsTable.Find(ProductSelection_1.PeriodDate_, "StartDate");
				
				IndexOf = PeriodsTable.IndexOf(Period);
				
				EmptyDataArea = Template.GetArea("TableRow|" + Count);
				EmptyDataAreaCrossEnding = Template.GetArea("TableRow|" + NumberOfCrossEndings);
				
				While CurrentPeriod < Period.ColumnNumber Do
					
					CurrentPeriod = CurrentPeriod + 1;
					DataArea = EmptyDataArea;
					DataAreaCrossEnd = EmptyDataAreaCrossEnding;
					
					If CurrentPeriod = Period.ColumnNumber Then
						If IndexOf < PeriodsTable.Count()-1 Then
							DataArea.Parameters.Fill(ProductSelection_1);
							Area = DataArea.Area("R1C1:R1C1");
							Area.Comment.Text = ProductSelection_1.Comment;
							SpreadsheetDocument.Join(DataArea);
						Else
							DataAreaCrossEnd.Parameters.Fill(ProductSelection_1);
							Area = DataAreaCrossEnd.Area("R1C1:R1C1");
							Area.Comment.Text = ProductSelection_1.Comment;
							SpreadsheetDocument.Join(DataAreaCrossEnd);
						EndIf; 
					Else
						SpreadsheetDocument.Join(DataArea);
					EndIf;
					
				EndDo;
				
				If CurrentPeriod = PeriodsTable.Count() Then
					CurrentPeriod = 0;
				EndIf;
				
				AmountsOfPeriods["Sum_"+Period.ColumnName] = AmountsOfPeriods["Sum_"+Period.ColumnName] + ProductSelection_1.Sum;
				
			Else
				AreaDatePeriod.Parameters.Fill(ProductSelection_1);
				AreaOrderDate.Parameters.Fill(ProductSelection_1);
				SpreadsheetDocument.Join(AreaDatePeriod);
				SpreadsheetDocument.Join(AreaOrderDate);
				
				DataArea.Parameters.Fill(ProductSelection_1);
				Area = DataArea.Area("R1C1:R1C1");
				Area.Comment.Text = ProductSelection_1.Comment;
				SpreadsheetDocument.Join(DataArea);
			EndIf;
			
			Sum          = Sum          + ProductSelection_1.Sum;
			
		EndDo;
		
		// Additional product line formation if there is no data until the end of the period
		If CrossTable And CurrentPeriod <> 0 And CurrentPeriod < PeriodsTable.Count() Then
			While CurrentPeriod < PeriodsTable.Count() Do
				CurrentPeriod = CurrentPeriod + 1;
				If CurrentPeriod < PeriodsTable.Count() Then
					SpreadsheetDocument.Join(Template.GetArea("TableRow|" + Count));
				Else
					SpreadsheetDocument.Join(Template.GetArea("TableRow|" + NumberOfCrossEndings));
				EndIf;
			EndDo;
		EndIf;
		
		// We output the basement, in the event that we output the header
		If DisplayHeader Then
			RoomArea                   = Template.GetArea("TableFooter|LineNumber");
			UIArea                       = Template.GetArea("TableFooter|UniqueIdentifiers");
			AreaCodes                    = Template.GetArea("TableFooter|ColumnOfCodes");
			ProductArea                    = Template.GetArea("TableFooter|" + OwnGoods);
			DataArea                   = Template.GetArea("TableFooter|" + Count);
			DataAreaCrossEnd     = Template.GetArea("TableFooter|" + NumberOfCrossEndings);
			AreaDatePeriod               = Template.GetArea("TableFooter|DatePeriod");
			AreaOrderDate               = Template.GetArea("TableFooter|OrderDate");
			AreaCrossUnitOfMeasurement    = Template.GetArea("TableFooter|CrossUnitOfMeasurement");
			If Add_Fields.Count() > 0 Then
				ProductFieldArea         = Template.GetArea("TableFooter|" + ProductAddField + Format(Add_Fields.Count(), "NFD=0; NG=0"));
			EndIf;
			
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			SpreadsheetDocument.Join(ProductArea);
			For Each AdditionalField_ In Add_Fields Do
				SpreadsheetDocument.Join(ProductFieldArea);
			EndDo; 
			
			If PlanByAmount And Not CrossTable Then
				SpreadsheetDocument.Join(AreaDatePeriod);
				SpreadsheetDocument.Join(AreaOrderDate);
				DataArea.Parameters.Total = PrintFormGeneration.SumFormat(Sum);
				SpreadsheetDocument.Join(DataArea);
			ElsIf CrossTable Then
				SpreadsheetDocument.Join(AreaCrossUnitOfMeasurement);
				
				For Each Period In PeriodsTable Do
					If Period.Active_ And Period.ColumnNumber <= 0 Then
						Continue;
					EndIf; 
					
					If PlanByAmount Then
						DataArea.Parameters.Total = PrintFormGeneration.SumFormat(AmountsOfPeriods["Sum_"+Period.ColumnName]);
					EndIf;
					SpreadsheetDocument.Join(DataArea);
				EndDo;
			Else
				SpreadsheetDocument.Join(AreaDatePeriod);
				SpreadsheetDocument.Join(AreaOrderDate);
				SpreadsheetDocument.Join(DataArea);
			EndIf;
			
			EndOfIssue = SpreadsheetDocument.TableHeight;
			
			// We output the Amount in words
			TemplateArea = Template.GetArea("TotalString");
			If PlanByAmount Then
				
				AmountToBeRegistered = Sum;
				
				TotalString = NStr("vi = 'Toàn bộ tên gọi %NumberOfTitles%, số tiền %DocumentAmount%';
									|ru = 'Всего наименований %NumberOfTitles%, на сумму %DocumentAmount%';
									|en = 'Total items %NumberOfTitles% in the amount of %DocumentAmount%'; fa = 'Total items %NumberOfTitles% in the amount of %DocumentAmount%';
									|it = 'Totale articoli %NumberOfTitles%, per l''importo di %DocumentAmount%';
									|pl = 'Razem przedmiotów %NumberOfTitles%, w kwocie %DocumentAmount%';
									|tr = 'Toplam tanım %NumberOfTitles%, tutar %DocumentAmount%'", Common.DefaultLanguageCode());
				TotalString = StrReplace(TotalString, "%NumberOfTitles%", LineNumber);
				TotalString = StrReplace(TotalString, "%DocumentAmount%", PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
				TemplateArea.Parameters.TotalString = TotalString;
				
				SpreadsheetDocument.Put(TemplateArea);
				
				TemplateArea = Template.GetArea("AmountInWords");
				TemplateArea.Parameters.AmountInWords  = ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency);
				SpreadsheetDocument.Put(TemplateArea);
				
			Else
				TotalString = NStr("vi = 'Toàn bộ tên gọi %NumberOfTitles%.';
									|ru = 'Всего наименований %NumberOfTitles%.';
									|en = 'Total items %NumberOfTitles%.'; fa = 'Total items %NumberOfTitles%.';
									|it = 'Totale articoli %NumberOfTitles%.';
									|pl = 'Razem przedmiotów %NumberOfTitles%.';
									|tr = 'Toplam tanım %NumberOfTitles%.'", Common.DefaultLanguageCode());
				TotalString = StrReplace(TotalString, "%NumberOfTitles%", LineNumber);
				TemplateArea.Parameters.TotalString = TotalString;
				
				SpreadsheetDocument.Put(TemplateArea);
				
			EndIf;
			
			// Output signatures
			TemplateArea = Template.GetArea("Signatures");
			
			If ValueIsFilled(PrintData.ResponsibleIndividual) Then
				TemplateArea.Parameters.EmployeeResponsiblePresentation =
					PersonsTM.IndividualShortName(PrintData.ResponsibleIndividual, PrintData.Date);
				TemplateArea.Parameters.EmployeeResponsible = PrintData.ResponsibleIndividual;
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		
		SpreadsheetDocument.PutHorizontalPageBreak();
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
		If CrossTable Then
			ThereAreCrossTables = True;
		EndIf; 
		If PlanByAmount Then
			ThereAreDocumentsWithAmounts = True;
		EndIf; 
		
	EndDo;
	
	If PrintData.Count() = 1 And ThereAreCrossTables Then
	
		HeaderArea = SpreadsheetDocument.Area(BeginningOfHeader, , EndOfHeader, );
		SpreadsheetDocument.RepeatOnRowPrint = HeaderArea;
		
		RoomArea = SpreadsheetDocument.Area(, 1, , NumberWidth);
		SpreadsheetDocument.RepeatOnColumnPrint = RoomArea;
	
	EndIf; 
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction

Function CreateAttachedExcelFile(DocumentRef, FormIdentifier) Export
	
	PrintParameters = New Structure;
	PrintParameters.Insert("DisplayHeader", False);
	
	DocumentsArray = New Array;
	DocumentsArray.Add(DocumentRef);
	
	PrintObjects = New ValueList;
	PrintObjects.Add(DocumentRef);
	
	SpreadsheetDocument = CreatePrintedFormOfPlan(DocumentsArray, PrintObjects, PrintParameters);
	TempFileName = GetTempFileName();
	SpreadsheetDocument.Write(TempFileName, SpreadsheetDocumentFileType.XLS97);
	
	FileAddressInTempStorage = PutToTempStorage(New BinaryData(TempFileName), FormIdentifier);
	CurrentDate = CurrentSessionDate();
	
	FileParameters = New Structure();
	FileParameters.Insert("Author", Users.AuthorizedUser());
	FileParameters.Insert("FilesOwner", DocumentRef);
	FileParameters.Insert("BaseName", "Excel" + " " + Format(CurrentDate, NStr("vi = 'ДФ=''дд.ММ.гггг ЧЧ.мм.сс''';
																				|ru = 'ДФ=''dd.MM.yyyy ЧЧ.мм.сс''';
																				|en = 'DF=''yyyy/MM/dd HH.mm.ss'''; fa = 'DF=''yyyy/MM/dd HH.mm.ss''';
																				|it = 'ДФ=''дд.ММ.гггг ЧЧ.мм.сс''';
																				|pl = 'DF=''dd.MM.yyyy HH.mm.ss''';
																				|tr = 'ДФ=''дд.ММ.гггг ЧЧ.мм.сс'''")));
	FileParameters.Insert("ExtensionWithoutPoint", "xls");
	FileParameters.Insert("ModificationTimeUniversal", CurrentDate);
	
	File = FilesOperations.AppendFile(FileParameters, FileAddressInTempStorage, Undefined);
	
	DeleteFiles(TempFileName);
	
	If File <> Undefined Then
		FilesOperationsInternal.BorrowFileToEditServer(File);
		FileData = FilesOperations.FileData(File, FormIdentifier, True);
		ExcelActionStructure = New Structure;
		ExcelActionStructure.Insert("AutoFilter", New Structure("RowStart1, ColumnStart1", 2, 2));
		
		// Hiding columns with the identifiers of the nomenclature and characteristics, packaging, partner, agreement, warehouse.
		ColumnsArray1 = New Array;
		ColumnsArray1.Add(3);
		ColumnsArray1.Add(4);
		ColumnsArray1.Add(5);
		ColumnsArray1.Add(6);
		ColumnsArray1.Add(7);
		ColumnsArray1.Add(8);
		ColumnsArray1.Add(9);
		ExcelActionStructure.Insert("HiddenColumns", ColumnsArray1);
		
		Return New Structure("FileData, File, ExcelActionStructure", FileData, File, ExcelActionStructure);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#Region ImportDataFromFile

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
// 
// Parameters:
// 	AddressOfUploadedData- String - address of the temporary storage with a table of values that
//                                   contains the downloaded data from the file.
// 	AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                       which is a copy of the table part of the document 
//                                       that needs to be filled in from the addressable Data table.
// 	ConflictsList - ValueTable - consists of:
//  * Id - Number - Id
//  * Column - String - column name
// 	FullTabularSectionName - String - full name of the table part
// 	AdditionalParameters - Structure - additional parameters passed from the source form.
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	Planning.MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters);
EndProcedure

Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	Planning.FillInListOfAmbiguities(ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters);
EndProcedure

#EndRegion

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//  ToDoList - See ToDoListServer.ToDoList
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "Document.PurchasePlan.Form.ListForm";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.PurchasePlan))
		And AccessRight("Insert", Metadata.Documents.PurchasePlan)
		And GetFunctionalOption("UsePurchasePlanning");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(*) AS ProcurementPlansPendingApproval,
	|	MIN(Plans.Status.Order) AS StatusOrder
	|FROM
	|	Document.PurchasePlan AS Plans
	|WHERE
	|	BEGINOFPERIOD(&CurrentDate, DAY) <= Plans.PeriodEnding
	|	AND CASE
	|	WHEN NOT Plans.Substitutional
	|		THEN Plans.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|	WHEN Plans.Substitutional
	|			AND Plans.Status <> VALUE(Enum.PlanStatuses.Upholded)
	|			AND Plans.Status.Order >= 2
	|		THEN TRUE
	|	ELSE FALSE
	|	END
	|	AND Plans.Posted";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "PurchasePlans";
	UserTaskParent.Presentation  = NStr("vi = 'Kế hoạch thống nhất dự tính';
										|ru = 'Планы ожидающие согласования';
										|en = 'Plans pending approval'; fa = 'Plans pending approval';
										|it = 'Piani in attesa di approvazione';
										|pl = 'Plany oczekujące na zatwierdzenie';
										|tr = 'Beklenen uyum planı'");
	UserTaskParent.HasToDoItems       = Result.ProcurementPlansPendingApproval > 0;
	UserTaskParent.Owner       = Planning.SubsystemPlanning();
	
	// ProcurementPlansPendingApproval
	FilterParameters = New Structure;
	If Enums.PlanStatuses[Result.StatusOrder] = Enums.PlanStatuses.AwaitingConfirmation Then
		FilterParameters.Insert("Status", Enums.PlanStatuses.AwaitingConfirmation);
	EndIf;
	FilterParameters.Insert("DeletionMark", False);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "ProcurementPlansPendingApproval";
	ToDoItem.HasToDoItems       = Result.ProcurementPlansPendingApproval > 0;
	ToDoItem.Presentation  = NStr("vi = 'Kế hoạch mua hàng';
									|ru = 'Планы закупок';
									|en = 'Purchase plans'; fa = 'برنامه‌های خرید';
									|it = 'Piani di acquisti';
									|pl = 'Plany zakupu';
									|tr = 'Satın alma planları'");
	ToDoItem.Count     = Result.ProcurementPlansPendingApproval;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "PurchasePlans";
	
	If Result.ProcurementPlansPendingApproval > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
