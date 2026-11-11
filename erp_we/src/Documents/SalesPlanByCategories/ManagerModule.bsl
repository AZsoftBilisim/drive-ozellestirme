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
	
	If TypeOf(Document) = Type("DocumentObject.SalesPlanByCategories") Then
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
		
		QueryTextSalesPlanByCategories(Query, QueryTexts, Registers);
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
	
EndProcedure

// Adds a command to create the document "sales Plan by category".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.SalesPlanByCategories) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.SalesPlanByCategories.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.SalesPlanByCategories);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseSalesPlansByCategories";
	

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
	
	Return True; // There are no additional checks for the document "Sales Plan by categories"
	
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
	|	Document.SalesPlanByCategories AS DocumentsTable
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
	
	PlanProfile                  = Parameters.TypeOfPlanDetails;
	Scenario                  = Parameters.ScenarioDetails;
	AttributePath1            = Parameters.AttributePath1;
	ThisIsASalesPlanByCategory = PlanProfile.PlanType = Enums.TypesOfPlans.SalesPlanByCategories;
	ThisIsASalesPlan             = PlanProfile.PlanType = Enums.TypesOfPlans.SalesPlan;
	ThisIsTheRemainderPlan 			= PlanProfile.PlanType = Enums.TypesOfPlans.PlanOfGoodsStock;
	
	UseSalesPlansByCategories = GetFunctionalOption("UseSalesPlansByCategories") 
		And Scenario.UseItInPlanningSalesByCategory
		And Not Scenario.UseCalculationBySalesSpeed;
	UseCalculationBySalesSpeed = GetFunctionalOption("UseSalesPlansByCategories") 
		And Scenario.UseItInPlanningSalesByCategory
		And Scenario.UseCalculationBySalesSpeed;
	UseSalesPlans_ 	= GetFunctionalOption("UseSalesPlans") 
		And Scenario.UseInSalesPlanning;
	
	CreatePropsWithSelection = PlanProfile.FillInPartner 
		Or PlanProfile.FillInStoreFormat 
		Or PlanProfile.FillInWarehouse 
		Or (PlanProfile.FillInBusinessUnit And (ThisIsASalesPlan Or ThisIsASalesPlanByCategory))
		Or (Scenario.PlanningByAssignments And Not PlanProfile.FillInAssignmentInTabularForm);
	
	
#Region SalesPlansByCategories
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"SalesPlansByCategories");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch bán hàng theo thể loại';
													|ru = 'План продаж по категориям';
													|en = 'Sales forecast by categories'; fa = 'پیش‌بینی فروش بر اساس دسته‌ها';
													|it = 'Piano di vendite per categorie';
													|pl = 'Plan sprzedaży wg kategorii';
													|tr = 'Kategorilere göre satış planı'"));
	AddnlParameter_.Insert("CreateProps", 	UseSalesPlansByCategories
		And (ThisIsASalesPlan 
			Or ThisIsASalesPlanByCategory 
			Or Not UseSalesPlans_));
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseSalesPlansByCategories 
		And (ThisIsASalesPlan 
			Or ThisIsASalesPlanByCategory 
			Or Not UseSalesPlans_));
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch bán hàng theo thể loại';
													|ru = 'План продаж по категориям';
													|en = 'Sales forecast by categories'; fa = 'پیش‌بینی فروش بر اساس دسته‌ها';
													|it = 'Piano di vendite per categorie';
													|pl = 'Plan sprzedaży wg kategorii';
													|tr = 'Kategorilere göre satış planı'"));
	AddnlParameter_.Insert("Details", 		"Document.SalesPlanByCategories");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("SalesPlansByCategories", AddnlParameter_);
#EndRegion
	
#Region SalesPlansByCategoriesWithFilter
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"SalesPlansByCategoriesWithFilter");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch bán hàng theo thể loại*';
													|ru = 'План продаж по категориям*';
													|en = 'Sales forecast by categories*'; fa = 'Sales forecast by categories*';
													|it = 'Piano vendite per categorie*';
													|pl = 'Plan sprzedaży według kategorii*';
													|tr = 'Kategorilere göre satış planı*'"));
	AddnlParameter_.Insert("CreateProps", 	UseSalesPlansByCategories 
		And CreatePropsWithSelection
		And (ThisIsASalesPlan 
			Or ThisIsASalesPlanByCategory 
			Or Not UseSalesPlans_));
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseSalesPlansByCategories 
		And CreatePropsWithSelection
		And (ThisIsASalesPlan 
			Or ThisIsASalesPlanByCategory 
			Or Not UseSalesPlans_));
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch bán hàng theo thể loại*';
													|ru = 'План продаж по категориям*';
													|en = 'Sales forecast by categories*'; fa = 'Sales forecast by categories*';
													|it = 'Piano vendite per categorie*';
													|pl = 'Plan sprzedaży według kategorii*';
													|tr = 'Kategorilere göre satış planı*'"));
	AddnlParameter_.Insert("Details", 		"Document.SalesPlanByCategories");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("SalesPlansByCategoriesWithFilter", AddnlParameter_);
#EndRegion

#Region SalesPlansByCategoriesBySalesSpeed
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"SalesPlansByCategoriesBySalesSpeed");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch bán hàng theo thể loại (theo tốc độ bán hàng)';
													|ru = 'План продаж по категориям (по скорости продаж)';
													|en = 'Sales forecast by categories (by sales speed)'; fa = 'پیش‌بینی فروش بر اساس دسته‌ها (بر اساس سرعت فروش)';
													|it = 'Piano vendite per categorie (per velocità delle vendite)';
													|pl = 'Plan sprzedaży według kategorii (według szybkości sprzedaży)';
													|tr = 'Kategorilere göre satış planı(satış hızına göre)'"));
	AddnlParameter_.Insert("CreateProps", 	UseCalculationBySalesSpeed 
		And (ThisIsASalesPlan 
			Or ThisIsASalesPlanByCategory 
			Or Not UseSalesPlans_));
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseCalculationBySalesSpeed 
		And (ThisIsASalesPlan 
			Or ThisIsASalesPlanByCategory 
			Or Not UseSalesPlans_));
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch bán hàng theo thể loại (theo tốc độ bán hàng)';
													|ru = 'План продаж по категориям (по скорости продаж)';
													|en = 'Sales forecast by categories (by sales speed)'; fa = 'پیش‌بینی فروش بر اساس دسته‌ها (بر اساس سرعت فروش)';
													|it = 'Piano vendite per categorie (per velocità delle vendite)';
													|pl = 'Plan sprzedaży według kategorii (według szybkości sprzedaży)';
													|tr = 'Kategorilere göre satış planı(satış hızına göre)'"));
	AddnlParameter_.Insert("Details", 		"Document.SalesPlanByCategories");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("SalesPlansByCategoriesBySalesSpeed", AddnlParameter_);
#EndRegion
	
#Region SalesPlansByCategoriesBySalesSpeedWithFilter
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"SalesPlansByCategoriesBySalesSpeedWithFilter");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Kế hoạch bán hàng theo thể loại (theo tốc độ bán hàng)*';
													|ru = 'План продаж по категориям (по скорости продаж)*';
													|en = 'Sales forecast by categories (by sales speed)*'; fa = 'Sales forecast by categories (by sales speed)*';
													|it = 'Piano vendite per categorie (per velocità delle vendite)*';
													|pl = 'Plan sprzedaży według kategorii (według szybkości sprzedaży)*';
													|tr = 'Kategorilere göre satış planı(satış hızına göre)*'"));
	AddnlParameter_.Insert("CreateProps", 	UseCalculationBySalesSpeed 
		And CreatePropsWithSelection 
		And (ThisIsASalesPlan 
			Or ThisIsASalesPlanByCategory 
			Or Not UseSalesPlans_));
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", 	UseCalculationBySalesSpeed 
		And CreatePropsWithSelection 
		And (ThisIsASalesPlan 
			Or ThisIsASalesPlanByCategory 
			Or Not UseSalesPlans_));
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Kế hoạch bán hàng theo thể loại (theo tốc độ bán hàng)*';
													|ru = 'План продаж по категориям (по скорости продаж)*';
													|en = 'Sales forecast by categories (by sales speed)*'; fa = 'Sales forecast by categories (by sales speed)*';
													|it = 'Piano vendite per categorie (per velocità delle vendite)*';
													|pl = 'Plan sprzedaży według kategorii (według szybkości sprzedaży)*';
													|tr = 'Kategorilere göre satış planı(satış hızına göre)*'"));
	AddnlParameter_.Insert("Details", 		"Document.SalesPlanByCategories");
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("SalesPlansByCategoriesBySalesSpeedWithFilter", AddnlParameter_);
#EndRegion

#Region FactOfSalesByCategories
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 				"FactOfSalesByCategories");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			?(CreatePropsWithSelection, NStr("vi = 'Thực tế bán hàng theo danh mục*';
																				|ru = 'Факт продаж по категориям*';
																				|en = 'Actual sales by categories*'; fa = 'Actual sales by categories*';
																				|it = 'Vendite effettive per categoria*';
																				|pl = 'Fakt sprzedaży według kategorii*';
																				|tr = 'Kategorilere göre satış bilgisi*'"), 
		NStr("vi = 'Thực tế bán hàng theo danh mục';
			|ru = 'Факт продаж по категориям';
			|en = 'Actual sales by categories'; fa = 'فروش واقعی بر اساس طبقات';
			|it = 'Fatto delle vendite per categorie';
			|pl = 'Faktyczna sprzedaż wg kategorii';
			|tr = 'Kategorilere göre satış bilgisi'")));
	AddnlParameter_.Insert("CreateProps", 	ThisIsASalesPlanByCategory);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", ThisIsASalesPlanByCategory);
	AddnlParameter_.Insert("OperandHeader", ?(CreatePropsWithSelection, NStr("vi = 'Thực tế bán hàng theo danh mục*';
																			|ru = 'Факт продаж по категориям*';
																			|en = 'Actual sales by categories*'; fa = 'Actual sales by categories*';
																			|it = 'Vendite effettive per categoria*';
																			|pl = 'Fakt sprzedaży według kategorii*';
																			|tr = 'Kategorilere göre satış bilgisi*'"), 
		NStr("vi = 'Thực tế bán hàng theo danh mục';
			|ru = 'Факт продаж по категориям';
			|en = 'Actual sales by categories'; fa = 'فروش واقعی بر اساس طبقات';
			|it = 'Fatto delle vendite per categorie';
			|pl = 'Faktyczna sprzedaż wg kategorii';
			|tr = 'Kategorilere göre satış bilgisi'")));
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsFacts");
	
	AddlParameters.Insert("FactOfSalesByCategories", AddnlParameter_);
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
	
	Templates.Insert("SalesPlansByCategories",                         GetTemplate("DCS_SalesPlansByCategories"));
	Templates.Insert("SalesPlansByCategoriesWithFilter",                 GetTemplate("DCS_SalesPlansByCategoriesWithFilter"));
	Templates.Insert("SalesPlansByCategoriesBySalesSpeed",         GetTemplate("DCS_SalesPlansByCategoriesBySalesSpeed"));
	Templates.Insert("SalesPlansByCategoriesBySalesSpeedWithFilter", GetTemplate("DCS_SalesPlansByCategoriesBySalesSpeedWithFilter"));
	Templates.Insert("FactOfSalesByCategories",                          GetTemplate("DCS_FactOfSalesByCategories"));
	Templates.Insert("ProductCategories",                               GetTemplate("DCS_ProductCategories"));
	Templates.Insert("ProductCategoriesOfWarehouseFormat",                   GetTemplate("DCS_ProductCategoriesOfWarehouseFormat"));
	
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
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.SalesPlanByCategories.ManagerModule.FillInDocumentUsingFormula");
	
	If Not Parameters.Property("FillInUsingFormula") Then
		Return;
	EndIf; 
	
	PeriodColumnName = "DateOfShipment";
	
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
	
	PeriodColumnName = "DateOfShipment";
	
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
		Enums.TypesOfPlans.SalesPlanByCategories, 
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
	
	PeriodColumnName = "DateOfShipment";
	
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

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	
	// All assignments for the Assignment field in the product categories table.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.ProductCategories.Purpose");
	
	// All assignments for the Assignment field in the table of product categories by period.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.ProductCategoriesByPeriods.Purpose");
	
	// All assignments for the Assignment field in the document header.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.Purpose");
	
	Return FormTemplate;
	
EndFunction

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
	|	DocumentData.Status AS Status,
	|	DocumentData.Department AS Department,
	|	DocumentData.StoreFormat AS StoreFormat,
	|	DocumentData.Scenario AS Scenario,
	|	DocumentData.PlanProfile AS PlanProfile,
	|	DocumentData.Substitutional AS Substitutional,
	|	DocumentData.Date AS Date,
	|	DocumentData.BudgetingScenario AS BudgetingScenario,
	|	DocumentData.BudgetingScenario.Currency AS ScenarioCurrency,
	|	DocumentData.PeriodEnding AS PeriodEnding,
	|	DocumentData.BeginOfPeriod AS BeginOfPeriod,
	|	DocumentData.Purpose AS Purpose,
	|	DocumentData.PlanProfile.FillInAssignmentInTabularForm AS FillInAssignmentInTabularForm
	|FROM
	|	Document.SalesPlanByCategories AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdditionalAttributes.LineNumber,
	|	AdditionalAttributes.Value
	|FROM
	|	Document.SalesPlanByCategories.AdditionalAttributes AS AdditionalAttributes
	|WHERE
	|	AdditionalAttributes.Ref = &Ref
	|";
	
	QueryResults = Query.ExecuteBatch(); 
	Attributes = QueryResults[0].Select();
	Attributes.Next();
	SelectionDetailRecords = QueryResults[1].Select();
	While SelectionDetailRecords.Next() Do
		If Not ValueIsFilled(SelectionDetailRecords.Value) Then
			Continue;
		EndIf;
		Query.SetParameter("AdditionalAttribute" + Format(SelectionDetailRecords.LineNumber, "NG=0"), SelectionDetailRecords.Value);
	EndDo;
	Query.SetParameter("BeginOfPeriod",             Attributes.BeginOfPeriod);
	Query.SetParameter("Status",                    Attributes.Status);
	Query.SetParameter("Department",             Attributes.Department);
	Query.SetParameter("Scenario",                  Attributes.Scenario);
	Query.SetParameter("PlanProfile",                  Attributes.PlanProfile);
	Query.SetParameter("Substitutional",                Attributes.Substitutional);
	Query.SetParameter("StoreFormat",            Attributes.StoreFormat);
	Query.SetParameter("PeriodEnding",          Attributes.PeriodEnding);
	Query.SetParameter("Purpose",                Attributes.Purpose);
	Query.SetParameter("FillInAssignmentInTabularForm",    Attributes.FillInAssignmentInTabularForm);
	Query.SetParameter("Date",                      Attributes.Date);
	Query.SetParameter("BudgetingScenario",    Attributes.BudgetingScenario);
	Query.SetParameter("ScenarioCurrency",            Attributes.ScenarioCurrency);
EndProcedure

Function QueryTextSalesPlanByCategories(Query, QueryTexts, Registers)
	
	RegisterName = "SalesPlansByCategories";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Status AS Status,
	|	CASE
	|		WHEN GoodsTable.DateOfShipment = DATETIME(1, 1, 1)
	|			THEN &BeginOfPeriod
	|		ELSE GoodsTable.DateOfShipment
	|	END AS Period,
	|	&Scenario AS Scenario,
	|	&PlanProfile AS PlanProfile,
	|	&StoreFormat AS StoreFormat,
	|	&Department AS Department,
	|	GoodsTable.Ref AS SalesPlanByCategories,
	|	GoodsTable.ProductCategory AS ProductCategory,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.SalesRank AS SalesRank,
	|	GoodsTable.Count AS Count
	|FROM
	|	Document.SalesPlanByCategories.ProductCategories AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND NOT GoodsTable.Canceled
	|	AND NOT GoodsTable.Substituted";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	
	FullDocumentName = "Document.SalesPlanByCategories"; 
	ParameterValues = New Structure;
	
	RedefiningParameterCalculation = New Structure;
		
	If RegisterName = "SalesPlansByCategories" Then
	
		QueryText = QueryTextSalesPlanByCategories(Query, QueryTexts, RegisterName);
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
	|	SalesPlanByCategorySubstitute.Ref AS ReplacementPlan_3,
	|	CASE
	|		WHEN &BeginOfPeriod > SalesPlanByCategorySubstitute.BeginOfPeriod
	|			THEN &BeginOfPeriod
	|		ELSE SalesPlanByCategorySubstitute.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < SalesPlanByCategorySubstitute.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE SalesPlanByCategorySubstitute.PeriodEnding
	|	END AS PeriodEnding,
	|	SalesPlanByCategorySubstitute.Status AS Status
	|FROM
	|	Document.SalesPlanByCategories AS SalesPlanByCategorySubstitute
	|WHERE
	|	SalesPlanByCategorySubstitute.PeriodEnding >= &BeginOfPeriod
	|	AND SalesPlanByCategorySubstitute.BeginOfPeriod <= &PeriodEnding
	|	AND SalesPlanByCategorySubstitute.Ref <> &Ref
	|	AND SalesPlanByCategorySubstitute.Posted
	|	AND SalesPlanByCategorySubstitute.PlanProfile = &PlanProfile
	|	AND (SalesPlanByCategorySubstitute.Status.Order >= &StatusIndex
	|			OR SalesPlanByCategorySubstitute.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND SalesPlanByCategorySubstitute.Date > &Date
	|	AND SalesPlanByCategorySubstitute.Department = &Department
	|	AND SalesPlanByCategorySubstitute.StoreFormat = &StoreFormat
	|	AND SalesPlanByCategorySubstitute.Warehouse = &Warehouse
	|	AND SalesPlanByCategorySubstitute.Purpose = &Purpose
	|
	|ORDER BY
	|	BeginOfPeriod,
	|	Status
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesPlanByCategorySubstituted.Ref AS SubstitutedPlan,
	|	CASE
	|		WHEN &BeginOfPeriod > SalesPlanByCategorySubstituted.BeginOfPeriod
	|			THEN &BeginOfPeriod
	|		ELSE SalesPlanByCategorySubstituted.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < SalesPlanByCategorySubstituted.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE SalesPlanByCategorySubstituted.PeriodEnding
	|	END AS PeriodEnding,
	|	SalesPlanByCategorySubstituted.Status AS Status
	|FROM
	|	Document.SalesPlanByCategories AS SalesPlanByCategorySubstituted
	|WHERE
	|	SalesPlanByCategorySubstituted.PeriodEnding >= &BeginOfPeriod
	|	AND SalesPlanByCategorySubstituted.BeginOfPeriod <= &PeriodEnding
	|	AND SalesPlanByCategorySubstituted.Ref <> &Ref
	|	AND SalesPlanByCategorySubstituted.Posted
	|	AND SalesPlanByCategorySubstituted.PlanProfile = &PlanProfile
	|	AND (SalesPlanByCategorySubstituted.Status.Order <= &StatusIndex
	|			OR SalesPlanByCategorySubstituted.Status = VALUE(Enum.PlanStatuses.Upholded)
	|				AND &Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation))
	|	AND SalesPlanByCategorySubstituted.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND SalesPlanByCategorySubstituted.Date < &Date
	|	AND SalesPlanByCategorySubstituted.Department = &Department
	|	AND SalesPlanByCategorySubstituted.StoreFormat = &StoreFormat
	|	AND SalesPlanByCategorySubstituted.Warehouse = &Warehouse
	|	AND SalesPlanByCategorySubstituted.Purpose = &Purpose
	|
	|ORDER BY
	|	BeginOfPeriod,
	|	Status";
	
	Query.SetParameter("Ref", Parameters.Ref);
	Query.SetParameter("PlanProfile", Parameters.PlanProfile);
	Query.SetParameter("Status", Parameters.Status);
	Query.SetParameter("StatusIndex", Enums.PlanStatuses.IndexOf(Parameters.Status));
	Query.SetParameter("Date", Parameters.Date);
	Query.SetParameter("Department", Parameters.Department);
	Query.SetParameter("StoreFormat", Parameters.StoreFormat);
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
//  Query
Function ReplacementRequest(Parameters) Export

	Query = New Query;
	Query.Text =
	"SELECT
	|	SalesPlansByCategoryTurnover_.Period AS CompositionPeriod,
	|	SalesPlansByCategoryTurnover_.Scenario AS Scenario,
	|	SalesPlansByCategoryTurnover_.Status AS Status,
	|	SalesPlansByCategoryTurnover_.Department AS Department,
	|	SalesPlansByCategoryTurnover_.Warehouse AS Warehouse,
	|	SalesPlansByCategoryTurnover_.StoreFormat AS StoreFormat,
	|	SalesPlansByCategoryTurnover_.CountTurnover AS Count,
	|	SalesPlansByCategoryTurnover_.ProductCategory AS ProductCategory,
	|	SalesPlansByCategoryTurnover_.Purpose AS Purpose
	|FROM
	|	AccumulationRegister.SalesPlansByCategories.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Record,
	|			Scenario = &Scenario
	|				AND PlanProfile = &PlanProfile
	|				AND &QueryTextFilterWarehouse
	|				AND (&FillInAssignmentInTabularForm
	|					OR Purpose = &Purpose)
	|				AND Status IN (&Statuses)
	|				AND &QueryTextFilterDepartment
	|				AND &QueryTextFilterStoreFormat) AS SalesPlansByCategoryTurnover_";
		
	Query.SetParameter("EndOfPeriod",   Parameters.OffsetPeriodEnd);
	Query.SetParameter("BeginOfPeriod",  Parameters.OffsetPeriodStart);
	Query.SetParameter("Department",  Parameters.Department);
	Query.SetParameter("Warehouse",          Parameters.Warehouse);
	Query.SetParameter("StoreFormat", Parameters.StoreFormat);
	Query.SetParameter("Statuses",        Parameters.Statuses);
	Query.SetParameter("Scenario",       Parameters.Scenario);
	Query.SetParameter("PlanProfile",       Parameters.PlanProfile);
	Query.SetParameter("FillInAssignmentInTabularForm", Parameters.FillInAssignmentInTabularForm);
	Query.SetParameter("Purpose",             Parameters.Purpose);
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterDepartment",
		?(ValueIsFilled(Parameters.Department),"Department = &Department","True"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterWarehouse",
		?(ValueIsFilled(Parameters.Warehouse),"Warehouse = &Warehouse","True"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterStoreFormat",
		?(ValueIsFilled(Parameters.StoreFormat),"StoreFormat = &StoreFormat","True"));
	
	Return Query;
	
EndFunction

#EndRegion

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
// 	AdditionalParameters - See PlanningClient.AdditionalParametersForDownloadingFromFile
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	ProductCategories = GetFromTempStorage(AddressOfMappingTable);// ValueTable
	DataToImport = GetFromTempStorage(AddressOfUploadedData);// ValueTable
	ProductCategories.Columns.Delete("AdditionalParameters");
	
	QueryTexts = New Array;
	QueryTexts.Add(QueryTextTTDownloadableData());
	QueryTexts.Add(QueryTextTTDataOfProductCategories());
	
	If AdditionalParameters.AssignmentsAreUsed Then
		QueryTexts.Add(Planning.QueryTextTTDestinationData());
	EndIf;
	If AdditionalParameters.CalculationOfSalesRateIsUsed Then
		QueryTexts.Add(QueryTextTTSalesRatingsData());
	EndIf;
	If AdditionalParameters.WarehousesAreUsed Then
		QueryTexts.Add(Planning.QueryTextTTWarehouseData());
	EndIf;

	QueryTexts.Add(RequestTextDownloadableDataProductCategories());
	
	Query = CreateConfigureRequest(QueryTexts, DataToImport, AdditionalParameters);// Query
	
	Result = Query.Execute().Unload();
	
	Id = 1;
	For Each String In Result Do
		
		If AdditionalParameters.CrossTable Then
			
			StringOfDataToLoad = DataToImport.Find(String.Id, "Id");
			
			For Each Period In AdditionalParameters.TimeIntervals Do
				
				// Parallel replenishment of the downloaded data for the correct operation of the BSP mechanism
				StringOfDataToLoad.Id = Id;
				FillPropertyValues(DataToImport.Add(), StringOfDataToLoad);
				
				NewRow = ProductCategories.Add();
				String.Id = Id;
				FillPropertyValues(NewRow, String);
				NewRow.Id = Id;
				NewRow.Count = String["Count_" + Period.ColumnName];
				NewRow.DateOfShipment = Period.StartDate;
				
				CreateAmbiguityRecords(ConflictsList, String, AdditionalParameters);
				
				Id = Id + 1;
				
			EndDo;
			
		Else
			
			NewRow = ProductCategories.Add();
			FillPropertyValues(NewRow, String);
			
			CreateAmbiguityRecords(ConflictsList, String, AdditionalParameters);
			
		EndIf;
		
	EndDo;
	
	PutToTempStorage(ProductCategories, AddressOfMappingTable);
EndProcedure

Procedure CreateAmbiguityRecords(ConflictsList, String, AdditionalParameters)
	
	If String.NumberOfProductCategories > 1 Then
		WritingAboutAmbiguity               = ConflictsList.Add();
		WritingAboutAmbiguity.Id = String.Id;
		WritingAboutAmbiguity.Column       = "ProductCategory";
	EndIf;
	
	If AdditionalParameters.CalculationOfSalesRateIsUsed And String.NumberOfSalesRatings > 1 Then
		WritingAboutAmbiguity               = ConflictsList.Add();
		WritingAboutAmbiguity.Id = String.Id;
		WritingAboutAmbiguity.Column       = "SalesRank";
	EndIf;
	
	If AdditionalParameters.AssignmentsAreUsed And String.NumberOfAppointments > 1 Then
		WritingAboutAmbiguity               = ConflictsList.Add();
		WritingAboutAmbiguity.Id = String.Id;
		WritingAboutAmbiguity.Column       = "Purpose";
	EndIf;
	
	If AdditionalParameters.WarehousesAreUsed And String.NumberOfWarehouses > 1 Then
		WritingAboutAmbiguity               = ConflictsList.Add();
		WritingAboutAmbiguity.Id = String.Id;
		WritingAboutAmbiguity.Column       = "Warehouse";
	EndIf;
	
EndProcedure

// Fill in the list of ambiguities.
// 
// Parameters:
//  FullTabularSectionName - String
//  ConflictsList - Array of ValueTableRow
//  ColumnName - String
//  LoadedValuesString - ValueTableRow
//  AdditionalParameters - See PlanningClient.AdditionalParametersForDownloadingFromFile
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	Query = New Query;
	
	If ColumnName = "ProductCategory" Then
		
		Query.Text =
		"SELECT
		|		ProductCategories.Ref AS Ref
		|	FROM
		|		Catalog.ProductCategories AS ProductCategories
		|		
		|	WHERE
		|		NOT &ProductCategory = """"
		|		AND ProductCategories.Description = &ProductCategory
		|";
		
		Query.SetParameter("ProductCategory", LoadedValuesString.ProductCategory);
		
	EndIf;
	
	If ColumnName = "Purpose" Then
		
		Query.Text =
		"SELECT
		|	Assignments.Ref AS Ref
		|FROM
		|	Catalog.Assignments AS Assignments
		|
		|WHERE
		|	NOT &Purpose = """"
		|	AND Assignments.Description = &Purpose
		|";
		
		Query.SetParameter("Purpose", LoadedValuesString.Purpose);
		
	EndIf;
	
	If ColumnName = "SalesRank" Then
		
		Query.Text =
		"SELECT
		|	SalesRatings.Ref AS Ref
		|FROM
		|	Catalog.SalesRanks AS SalesRatings
		|
		|WHERE
		|	NOT &SalesRank = """"
		|	AND SalesRatings.Description = &SalesRank
		|";
		
		Query.SetParameter("SalesRank", LoadedValuesString.SalesRank);
		
	EndIf;
	
	If ColumnName = "Warehouse" Then
		
		Query.Text =
		"SELECT
		|	Warehouses.Ref AS Ref
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|
		|WHERE
		|	NOT &Warehouse = """"
		|	AND Warehouses.Description = &Warehouse
		|";
		
		Query.SetParameter("Warehouse", LoadedValuesString.Warehouse);
		
	EndIf;
	
	If ValueIsFilled(Query.Text) Then
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
	EndIf;
EndProcedure

Function CreateConfigureRequest(QueryTexts, DataToImport, AdditionalParameters)
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	CrossTable = AdditionalParameters.CrossTable;
	FieldsQuantity = "";
	PeriodField = "";
	
	If CrossTable Then
		For Each Period In AdditionalParameters.TimeIntervals Do
			FieldsQuantity = FieldsQuantity + "
			|DataToImport.Count_" + Period.ColumnName + " AS Count_" +  Period.ColumnName + ",";
		EndDo;
	Else
		FieldsQuantity = "DataToImport.Count AS Count,";
		PeriodField = "DataToImport.DateOfShipment AS DateOfShipment,"
	EndIf;
	
	QueryText = StrReplace(QueryText, "&UploadedDataQuantity,", FieldsQuantity);
	QueryText = StrReplace(QueryText, "&DownloadableDataDateOfShipment,", PeriodField);
	
	// Assignments are used
	QueryText = StrReplace(QueryText, "&DownloadableDataDestination,",
		?(AdditionalParameters.AssignmentsAreUsed, "DataToImport.Purpose AS Purpose,", ""));
	
	QueryText = StrReplace(QueryText, "&Purpose,", ?(AdditionalParameters.AssignmentsAreUsed, "
		|	CASE
		|		WHEN ISNULL(DestinationData.NumberOfAppointments, 0) = 1
		|			THEN DestinationData.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,", ""));
	
	QueryText = StrReplace(QueryText, "&NumberOfAppointments,", 
		?(AdditionalParameters.AssignmentsAreUsed, "ISNULL(DestinationData.NumberOfAppointments, 0) AS NumberOfAppointments,", ""));
	
	QueryText = QueryText + ?(AdditionalParameters.AssignmentsAreUsed, "
		|	LEFT JOIN TTDestinationData AS DestinationData
		|	ON DestinationData.Id = DataToImport.Id", "");
	
	// Sales ratings are used
	QueryText = StrReplace(QueryText, "&DownloadableDataSalesRating,",
		?(AdditionalParameters.CalculationOfSalesRateIsUsed, "DataToImport.SalesRank AS SalesRank,", ""));
	
	QueryText = StrReplace(QueryText, "&SalesRank,", ?(AdditionalParameters.CalculationOfSalesRateIsUsed, "
		|	CASE
		|		WHEN ISNULL(SalesRatingsData.NumberOfSalesRatings, 0) = 1
		|			THEN SalesRatingsData.SalesRank
		|		ELSE VALUE(Catalog.SalesRanks.EmptyRef)
		|	END AS SalesRank,", ""));
	
	QueryText = StrReplace(QueryText, "&NumberOfSalesRatings,", 
		?(AdditionalParameters.CalculationOfSalesRateIsUsed, "ISNULL(SalesRatingsData.NumberOfSalesRatings, 0) AS NumberOfSalesRatings,", ""));
	
	QueryText = QueryText + ?(AdditionalParameters.CalculationOfSalesRateIsUsed, "
		|	LEFT JOIN TTSalesRatingsData AS SalesRatingsData
		|	ON SalesRatingsData.Id = DataToImport.Id", "");
	
	// Warehouses are used
	QueryText = StrReplace(QueryText, "&UploadedDataWarehouse,",
		?(AdditionalParameters.WarehousesAreUsed, "DataToImport.Warehouse AS Warehouse,", ""));
	
	QueryText = StrReplace(QueryText, "&Warehouse,", ?(AdditionalParameters.WarehousesAreUsed, "
		|	CASE
		|		WHEN ISNULL(WarehouseData_2.NumberOfWarehouses, 0) = 1
		|			THEN WarehouseData_2.Warehouse
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END AS Warehouse,", ""));
	
	QueryText = StrReplace(QueryText, "&NumberOfWarehouses,", 
		?(AdditionalParameters.WarehousesAreUsed, "ISNULL(WarehouseData_2.NumberOfWarehouses, 0) AS NumberOfWarehouses,", ""));
	
	QueryText = QueryText + ?(AdditionalParameters.WarehousesAreUsed, "
		|	LEFT JOIN TTWarehouseData AS WarehouseData_2
		|	ON WarehouseData_2.Id = DataToImport.Id", "");
	
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataToImport", DataToImport);
	
	Return Query;
	
EndFunction

Function QueryTextTTDownloadableData()
	
	QueryText =
	"SELECT
	|	DataToImport.Id     AS Id,
	|	DataToImport.ProductCategory AS ProductCategory,
	|	&DownloadableDataDestination,
	|	&DownloadableDataSalesRating,
	|	&UploadedDataWarehouse,
	|	&UploadedDataQuantity,
	|	&DownloadableDataDateOfShipment,
	|	DataToImport.Comment       AS Comment
	|INTO TTDownloadableData
	|FROM
	|	&DataToImport AS DataToImport
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDataOfProductCategories()
	
	QueryText =
	"SELECT
	|	ProductCategories.Id                           AS Id,
	|	MAX(ProductCategories.ProductCategory)             AS ProductCategory,
	|	COUNT(DISTINCT ProductCategories.ProductCategory) AS NumberOfProductCategories
	|INTO TTDataOfProductCategories
	|FROM
	|	(SELECT
	|		DataToImport.Id   AS Id,
	|		ProductCategories.Ref          AS ProductCategory
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.ProductCategories AS ProductCategories
	|		ON ProductCategories.Description = DataToImport.ProductCategory
	|
	|	WHERE
	|		NOT DataToImport.ProductCategory = """"
	|
	|	) AS ProductCategories
	|
	|GROUP BY
	|	ProductCategories.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTSalesRatingsData()
	QueryText = "
	|SELECT
	|	SalesRatings.Id                       AS Id,
	|	MAX(SalesRatings.SalesRank)             AS SalesRank,
	|	COUNT(DISTINCT SalesRatings.SalesRank) AS NumberOfSalesRatings
	|INTO TTSalesRatingsData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		SalesRatings.Ref           AS SalesRank
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.SalesRanks AS SalesRatings
	|		ON SalesRatings.Description = DataToImport.SalesRank
	|
	|	WHERE
	|		NOT DataToImport.SalesRank = """"
	|	) AS SalesRatings
	|
	|GROUP BY
	|	SalesRatings.Id
	|
	|INDEX BY
	|	Id";
	
	Return QueryText;
EndFunction

Function RequestTextDownloadableDataProductCategories()
	
	QueryText =
	"SELECT
	|	DataToImport.Id AS Id,
	|	CASE
	|		WHEN ISNULL(DataOfProductCategories.NumberOfProductCategories, 0) = 1
	|			THEN DataOfProductCategories.ProductCategory
	|		ELSE VALUE(Catalog.ProductCategories.EmptyRef)
	|	END AS ProductCategory,
	|	&Purpose,
	|	&SalesRank,
	|	&Warehouse,
	|	ISNULL(DataOfProductCategories.NumberOfProductCategories, 0) AS NumberOfProductCategories,
	|	&NumberOfAppointments,
	|	&NumberOfSalesRatings,
	|	&NumberOfWarehouses,
	|	&UploadedDataQuantity,
	|	&DownloadableDataDateOfShipment,
	|	DataToImport.Comment  AS Comment
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	LEFT JOIN TTDataOfProductCategories AS DataOfProductCategories
	|	ON DataOfProductCategories.Id = DataToImport.Id
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Sales plan by category
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "SalesPlanByCategories";
	PrintCommand.Presentation = NStr("vi = 'Kế hoạch bán hàng theo thể loại';
									|ru = 'План продаж по категориям';
									|en = 'Sales forecast by categories'; fa = 'پیش‌بینی فروش بر اساس دسته‌ها';
									|it = 'Piano di vendite per categorie';
									|pl = 'Plan sprzedaży wg kategorii';
									|tr = 'Kategorilere göre satış planı'");
	PrintCommand.CheckPostingBeforePrint = True;

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SalesPlanByCategories") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"SalesPlanByCategories",
			NStr("vi = 'Kế hoạch bán hàng theo thể loại';
				|ru = 'План продаж по категориям';
				|en = 'Sales forecast by categories'; fa = 'پیش‌بینی فروش بر اساس دسته‌ها';
				|it = 'Piano di vendite per categorie';
				|pl = 'Plan sprzedaży wg kategorii';
				|tr = 'Kategorilere göre satış planı'"),
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
	WithdrawWarehouse 			= True;
	DisplayStoreFormat	= True;
	DisplayVHFWarehouse 		= True;
	DisplaySalesRating	= True;
	
	If PrintParameters <> Undefined And Not PrintParameters.Property("OutputScript", OutputScript) Then
		OutputScript 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("DisplayPeriodStatus", DisplayPeriodStatus) Then
		DisplayPeriodStatus 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("OutputDivision", OutputDivision) Then
		OutputDivision 	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("WithdrawWarehouse", WithdrawWarehouse) Then
		WithdrawWarehouse 			= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("DisplayStoreFormat", DisplayStoreFormat) Then
		DisplayStoreFormat	= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("DisplayVHFWarehouse", DisplayVHFWarehouse) Then
		DisplayVHFWarehouse 		= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("DisplayVHFWarehouse", DisplayVHFWarehouse) Then
		DisplayVHFWarehouse 		= True;
	EndIf;
	If PrintParameters <> Undefined And Not PrintParameters.Property("DisplaySalesRating", DisplaySalesRating) Then
		DisplaySalesRating	= True;
	EndIf;
	
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
	|	CatPlanProfiles.FillInWarehouse                    AS FillInWarehouse,
	|	CatPlanProfiles.FillInStoreFormat           AS FillInStoreFormat,
	|	CatPlanProfiles.FillInWarehouseInTabularForm                 AS FillInWarehouseInTabularForm,
	|	PlanningScenarios.ShowNumberOfPeriod     AS ShowNumberOfPeriod,
	|	PlanningScenarios.UseCalculationBySalesSpeed AS FillInSalesRating,
	|	Users.Individual                     AS ResponsibleIndividual,
	|	DocumentTable.Department                  AS Department,
	|	DocumentTable.StoreFormat                 AS StoreFormat,
	|	DocumentTable.Warehouse                          AS Warehouse,
	|	DocumentTable.Purpose                     AS Purpose,
	|	PlanningScenarios.PlanningByAssignments  AS PlanningByAssignments,
	|	CatPlanProfiles.FillInAssignmentInTabularForm            AS FillInAssignmentInTabularForm
	|FROM
	|	Document.SalesPlanByCategories AS DocumentTable
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
	|	GoodsTable.ProductCategory                 AS ProductCategory,
	|	GoodsTable.ProductCategory.Description    AS ProductCategoryName,
	|	GoodsTable.LineNumber                       AS LineNumber,
	|	GoodsTable.DateOfShipment                      AS PeriodDate_,
	|	GoodsTable.Count                        AS Count,
	|	GoodsTable.Comment                       AS Comment,
	|	GoodsTable.Warehouse                             AS Warehouse,
	|	GoodsTable.SalesRank                     AS SalesRank,
	|	GoodsTable.Purpose.Description           AS PurposeName,
	|	GoodsTable.Purpose                        AS Purpose
	|FROM
	|	Document.SalesPlanByCategories.ProductCategories AS GoodsTable
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
	|	NestedQuery.ProductCategory,
	|	NestedQuery.ProductCategory.Description,
	|	MIN(NestedQuery.LineNumber),
	|	NestedQuery.PeriodDate_,
	|	SUM(NestedQuery.Count),
	|	MAX(NestedQuery.Comment),
	|	NestedQuery.Warehouse,
	|	NestedQuery.SalesRank,
	|	NestedQuery.Purpose.Description,
	|	NestedQuery.Purpose
	|FROM
	|	(SELECT
	|		GoodsTable.Ref AS Ref,
	|		GoodsTable.ProductCategory AS ProductCategory,
	|		CASE DocumentTable.Periodicity
	|			WHEN VALUE(Enum.Periodicity.YEAR)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfShipment, YEAR)
	|			WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfShipment, HALFYEAR)
	|			WHEN VALUE(Enum.Periodicity.QUARTER)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfShipment, QUARTER)
	|			WHEN VALUE(Enum.Periodicity.MONTH)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfShipment, MONTH)
	|			WHEN VALUE(Enum.Periodicity.TENDAYS)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfShipment, TENDAYS)
	|			WHEN VALUE(Enum.Periodicity.WEEK)
	|				THEN BEGINOFPERIOD(GoodsTable.DateOfShipment, WEEK)
	|			ELSE GoodsTable.DateOfShipment
	|		END AS PeriodDate_,
	|		GoodsTable.LineNumber AS LineNumber,
	|		CASE WHEN GoodsTable.Canceled THEN 0 ELSE GoodsTable.Count END AS Count,
	|		CASE WHEN GoodsTable.Canceled THEN """" ELSE CAST(GoodsTable.Comment AS STRING(1000)) END AS Comment,
	|		GoodsTable.Warehouse                 AS Warehouse,
	|		GoodsTable.SalesRank         AS SalesRank,
	|		GoodsTable.Purpose            AS Purpose
	|	FROM
	|		Document.SalesPlanByCategories.ProductCategories AS GoodsTable
	|			INNER JOIN Document.SalesPlanByCategories AS DocumentTable
	|			ON GoodsTable.Ref = DocumentTable.Ref
	|	WHERE
	|		(&DefaultCrossTable
	|				OR GoodsTable.Ref.CrossTable)
	|		AND GoodsTable.Ref IN(&DocumentsArray)
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.ProductCategory,
	|	NestedQuery.ProductCategory.Description,
	|	NestedQuery.Warehouse,
	|	NestedQuery.SalesRank,
	|	NestedQuery.PeriodDate_,
	|	NestedQuery.Purpose,
	|	NestedQuery.Purpose.Description
	|
	|ORDER BY
	|	Ref,
	|	LineNumber,
	|	ProductCategoryName,
	|	PurposeName,
	|	Warehouse,
	|	SalesRank,
	|	PeriodDate_
	|TOTALS BY
	|	Ref");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_SalesPlanByCategories_SalesPlanByCategories";
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	Query.SetParameter("DefaultCrossTable", DefaultCrossTable);
	Query.SetParameter("DefaultTable", DefaultTable);
	
	ResultsArray 		= Query.ExecuteBatch(); 
	PrintData			= ResultsArray[0].Select();
	SelectionByDocuments 	= ResultsArray[1].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	ThereAreCrossTables = False;
	BeginningOfHeader = 0;
	EndOfHeader = 0;
	NumberWidth = 0;
	EndOfIssue = 0;
	
	//DEBAG
	PlanByAmount = False;
	
	While PrintData.Next() Do
		
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
		Template = PrintManagement.PrintFormTemplate("Document.SalesPlanByCategories.PF_MXL_SalesPlanByCategories");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the plan
		If DisplayHeader Then
			
			TemplateArea = Template.GetArea("Title");
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
			
			TitleText = TMCommonUseClientServer.GenerateDocumentTitle(
				PrintData,
				NStr("vi = 'Kế hoạch bán hàng theo thể loại';
					|ru = 'План продаж по категориям';
					|en = 'Sales forecast by categories'; fa = 'پیش‌بینی فروش بر اساس دسته‌ها';
					|it = 'Piano di vendite per categorie';
					|pl = 'Plan sprzedaży wg kategorii';
					|tr = 'Kategorilere göre satış planı'", Common.DefaultLanguageCode()));
			TemplateArea.Parameters.TitleText = TitleText;
			SpreadsheetDocument.Put(TemplateArea);
			
			If OutputScript Then
				TemplateArea                                  = Template.GetArea("Scenario");
				ScriptPresentation                          = String(PrintData.Scenario) + ", "+ String(PrintData.Periodicity);
				TemplateArea.Parameters.ScriptPresentation  = ScriptPresentation;
				TemplateArea.Parameters.Scenario               = PrintData.Scenario;
				PresentationOfPlanView                         = String(PrintData.PlanProfile);
				TemplateArea.Parameters.PresentationOfPlanView = PresentationOfPlanView;
				TemplateArea.Parameters.PlanProfile               = PrintData.PlanProfile;
				SpreadsheetDocument.Put(TemplateArea);
			EndIf;
			
			If DisplayPeriodStatus Then
				TemplateArea                                = Template.GetArea("Period");
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
			
			If PrintData.FillInStoreFormat And DisplayStoreFormat Then
				TemplateArea                                        = Template.GetArea("StoreFormat");
				StoreFormatPresentation                         = String(PrintData.StoreFormat);
				TemplateArea.Parameters.StoreFormatPresentation = StoreFormatPresentation;
				TemplateArea.Parameters.StoreFormat               = PrintData.StoreFormat;
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
			StructureOfAdditionalField = New Structure;
			StructureOfAdditionalField.Insert("Title", NStr("vi = 'Ấn định';
															|ru = 'Назначение';
															|en = 'Assignment'; fa = 'تخصیص';
															|it = 'Destinazione';
															|pl = 'Przeznaczenie';
															|tr = 'Atama'", Common.DefaultLanguageCode()));
			StructureOfAdditionalField.Insert("ValueColumn_", "Purpose");
			Add_Fields.Add(StructureOfAdditionalField);
		EndIf;
		
		If PrintData.FillInWarehouseInTabularForm Then
			StructureOfAdditionalField = New Structure;
			StructureOfAdditionalField.Insert("Title", NStr("vi = 'Kho bãi';
															|ru = 'Склад';
															|en = 'Warehouse'; fa = 'Warehouse';
															|it = 'Magazzino';
															|pl = 'Magazyn';
															|tr = 'Ambar'", Common.DefaultLanguageCode()));
			StructureOfAdditionalField.Insert("ValueColumn_", "Warehouse");
			Add_Fields.Add(StructureOfAdditionalField);
		EndIf;
		If PrintData.FillInSalesRating Then
			StructureOfAdditionalField = New Structure;
			StructureOfAdditionalField.Insert("Title", NStr("vi = 'Đánh giá bán hàng';
															|ru = 'Рейтинг продаж';
															|en = 'Sales rank'; fa = 'رتبه فروش';
															|it = 'Ranking delle vendite';
															|pl = 'Ranking sprzedaży';
															|tr = 'Satış sıralaması'", Common.DefaultLanguageCode()));
			StructureOfAdditionalField.Insert("ValueColumn_", "SalesRank");
			Add_Fields.Add(StructureOfAdditionalField);
		EndIf;
		
		AreaNameCount = ?(CrossTable, "NumberOfCrosses","Count");
		
		UseItemVariants = False;
		WithoutCharacteristics = Not (DisplayHeader Or UseItemVariants);
		// Calculation of the column width of the product category
		ColumnWidthProductCategory = Template.Area("ProductCategory").ColumnWidth;
		
		If Add_Fields.Count() > 0 Then
			ColumnWidthProductCategory = ColumnWidthProductCategory -Template.Area("ProductCategoryAdditionalField"+ Format(Add_Fields.Count(), "NFD=0; NG=0")).ColumnWidth * Add_Fields.Count();
		EndIf; 
		Template.Area("ProductCategory").ColumnWidth = ColumnWidthProductCategory;
		
		TextOnFirstPage = 2;
		PeriodsOnPage = 6;
		
		RoomArea                   = Template.GetArea("TableHeader|LineNumber");
		UIArea                       = Template.GetArea("TableHeader|UniqueIdentifiers");
		AreaProductCategory        = Template.GetArea("TableHeader|ProductCategory");
		DataArea                   = Template.GetArea("TableHeader|" + AreaNameCount);
		DataAreaCrossEnd     = Template.GetArea("TableHeader|NumberOfCrossEndings");
		AreaDatePeriod               = Template.GetArea("TableHeader|DatePeriod");
		If Add_Fields.Count() > 0 Then
			AreaProductCategoryAdditionalField = Template.GetArea("TableHeader|ProductCategoryAdditionalField"+ Format(Add_Fields.Count(), "NFD=0; NG=0"));
		EndIf; 
		
		SpreadsheetDocument.Put(RoomArea);
		If Not DisplayHeader Then
			SpreadsheetDocument.Join(UIArea);
		EndIf;
		
		SpreadsheetDocument.Join(AreaProductCategory);
		
		For Each AdditionalField_ In Add_Fields Do
			AreaProductCategoryAdditionalField.Parameters.Title = AdditionalField_.Title;
			SpreadsheetDocument.Join(AreaProductCategoryAdditionalField);
		EndDo; 
		
		PageNumber = 1;
		If CrossTable Then
			For Each Period In PeriodsTable Do
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
			SpreadsheetDocument.Join(DataArea);
		EndIf; 
		
		BeginningOfHeader = SpreadsheetDocument.TableHeight - RoomArea.TableHeight +1;
		EndOfHeader = SpreadsheetDocument.TableHeight;
		NumberWidth = RoomArea.TableWidth;
		
		RoomArea                   = Template.GetArea("TableRow|LineNumber");
		UIArea                       = Template.GetArea("TableRow|UniqueIdentifiers");
		AreaProductCategory        = Template.GetArea("TableRow|ProductCategory");
		DataArea                   = Template.GetArea("TableRow|" + AreaNameCount);
		DataAreaCrossEnd     = Template.GetArea("TableRow|NumberOfCrossEndings");
		AreaDatePeriod               = Template.GetArea("TableRow|DatePeriod");
		If Add_Fields.Count() > 0 Then
			AreaProductCategoryAdditionalField = Template.GetArea("TableRow|ProductCategoryAdditionalField"+ Format(Add_Fields.Count(), "NFD=0; NG=0") );
		EndIf;
		
		CurrentRow  = New Structure("ProductCategory, Warehouse, SalesRank, Purpose");
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
							SpreadsheetDocument.Join(Template.GetArea("TableRow|" + AreaNameCount));
						Else
							SpreadsheetDocument.Join(Template.GetArea("TableRow|NumberOfCrossEndings"));
						EndIf;
					EndDo;
				EndIf;
				
				FillPropertyValues(CurrentRow, ProductSelection_1);
				CurrentPeriod = 0;
				
				LineNumber = LineNumber + 1;
				
				RoomArea.Parameters.LineNumber = LineNumber;
				SpreadsheetDocument.Put(RoomArea);
				
				If Not DisplayHeader Then
					UIArea.Parameters.UniqueIdentifierProductCategory = String(ProductSelection_1.ProductCategory.UUID());
					UIArea.Parameters.UniqueWarehouseID             = String(ProductSelection_1.Warehouse.UUID());
					UIArea.Parameters.UniqueIdentifierSalesRating     = String(ProductSelection_1.SalesRank.UUID());
					UIArea.Parameters.UniqueIdentifierPurpose        = String(ProductSelection_1.Purpose.UUID());
					
					SpreadsheetDocument.Join(UIArea);
				EndIf;
				
				AreaProductCategory.Parameters.Fill(ProductSelection_1);
				
				AreaProductCategory.Parameters.ProductCategory = ProductSelection_1.ProductCategoryName;
				
				SpreadsheetDocument.Join(AreaProductCategory);
				
				For Each AdditionalField_ In Add_Fields Do
					AreaProductCategoryAdditionalField.Parameters.Value = ProductSelection_1[AdditionalField_.ValueColumn_];
					SpreadsheetDocument.Join(AreaProductCategoryAdditionalField);
				EndDo;
				
			EndIf;
			
			If CrossTable Then
				
				Period = PeriodsTable.Find(ProductSelection_1.PeriodDate_, "StartDate");
				
				IndexOf = PeriodsTable.IndexOf(Period);
				
				EmptyDataArea = Template.GetArea("TableRow|" + AreaNameCount);
				EmptyDataAreaCrossEnding = Template.GetArea("TableRow|NumberOfCrossEndings");
				
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
				
			Else
				AreaDatePeriod.Parameters.Fill(ProductSelection_1);
				SpreadsheetDocument.Join(AreaDatePeriod);
				
				DataArea.Parameters.Fill(ProductSelection_1);
				Area = DataArea.Area("R1C1:R1C1");
				Area.Comment.Text = ProductSelection_1.Comment;
				SpreadsheetDocument.Join(DataArea);
			EndIf;
			
		EndDo;
		
		// Additional product line formation if there is no data until the end of the period
		If CrossTable And CurrentPeriod <> 0 And CurrentPeriod < PeriodsTable.Count() Then
			While CurrentPeriod < PeriodsTable.Count() Do
				CurrentPeriod = CurrentPeriod + 1;
				If CurrentPeriod < PeriodsTable.Count() Then
					SpreadsheetDocument.Join(Template.GetArea("TableRow|" + AreaNameCount));
				Else
					SpreadsheetDocument.Join(Template.GetArea("TableRow|NumberOfCrossEndings"));
				EndIf;
			EndDo;
		EndIf;
		
		// We output the basement, in the event that we output the header
		If DisplayHeader Then
			RoomArea                   = Template.GetArea("TableFooter|LineNumber");
			UIArea                       = Template.GetArea("TableFooter|UniqueIdentifiers");
			AreaProductCategory        = Template.GetArea("TableFooter|ProductCategory");
			DataArea                   = Template.GetArea("TableFooter|" + AreaNameCount);
			DataAreaCrossEnd     = Template.GetArea("TableFooter|NumberOfCrossEndings");
			AreaDatePeriod               = Template.GetArea("TableFooter|DatePeriod");
			If Add_Fields.Count() > 0 Then
				AreaProductCategoryAdditionalField = Template.GetArea("TableFooter|ProductCategoryAdditionalField"+ Format(Add_Fields.Count(), "NFD=0; NG=0") );
			EndIf;
			
			SpreadsheetDocument.Put(RoomArea);
			
			SpreadsheetDocument.Join(AreaProductCategory);
			For Each AdditionalField_ In Add_Fields Do
				SpreadsheetDocument.Join(AreaProductCategoryAdditionalField);
			EndDo; 
			
			If CrossTable Then
				
				For Each Period In PeriodsTable Do
					If Period.Active_ And Period.ColumnNumber <= 0 Then
						Continue;
					EndIf; 
					
					SpreadsheetDocument.Join(DataArea);
				EndDo;
			Else
				SpreadsheetDocument.Join(AreaDatePeriod);
				SpreadsheetDocument.Join(DataArea);
			EndIf;
			
			EndOfIssue = SpreadsheetDocument.TableHeight;
			
			TemplateArea = Template.GetArea("TotalString");
			TotalString = NStr("vi = 'Toàn bộ tên gọi %NumberOfTitles%.';
								|ru = 'Всего наименований %NumberOfTitles%.';
								|en = 'Total items %NumberOfTitles%.'; fa = 'Total items %NumberOfTitles%.';
								|it = 'Totale articoli %NumberOfTitles%.';
								|pl = 'Razem przedmiotów %NumberOfTitles%.';
								|tr = 'Toplam tanım %NumberOfTitles%.'", Common.DefaultLanguageCode());
			TotalString = StrReplace(TotalString, "%NumberOfTitles%", LineNumber);
			TemplateArea.Parameters.TotalString = TotalString;
			
			SpreadsheetDocument.Put(TemplateArea);
			
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
		ExcelActionStructure.Insert("HiddenColumns", ColumnsArray1);
		
		Return New Structure("FileData, File, ExcelActionStructure", FileData, File, ExcelActionStructure);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//  ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "Document.SalesPlanByCategories.Form.ListForm";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.SalesPlanByCategories))
		And AccessRight("Insert", Metadata.Documents.SalesPlanByCategories)
		And GetFunctionalOption("UseSalesPlansByCategories");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(*) AS SalesPlansByCategoryPendingApproval,
	|	MIN(Plans.Status.Order) AS StatusOrder
	|FROM
	|	Document.SalesPlanByCategories AS Plans
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
	UserTaskParent = ToDoList.Find("PurchasePlans", "Id");
	If UserTaskParent = Undefined Then
		UserTaskParent = ToDoList.Add();
		UserTaskParent.Id  = "PurchasePlans";
		UserTaskParent.Presentation  = NStr("vi = 'Kế hoạch thống nhất dự tính';
											|ru = 'Планы ожидающие согласования';
											|en = 'Plans pending approval'; fa = 'Plans pending approval';
											|it = 'Piani in attesa di approvazione';
											|pl = 'Plany oczekujące na zatwierdzenie';
											|tr = 'Beklenen uyum planı'");
		UserTaskParent.Owner       = Planning.SubsystemPlanning();
	EndIf;
	
	// ProcurementPlansPendingApproval
	FilterParameters = New Structure;
	If Enums.PlanStatuses[Result.StatusOrder] = Enums.PlanStatuses.AwaitingConfirmation Then
		FilterParameters.Insert("Status", Enums.PlanStatuses.AwaitingConfirmation);
	EndIf;
	FilterParameters.Insert("DeletionMark", False);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "SalesPlansByCategoryPendingApproval";
	ToDoItem.HasToDoItems       = Result.SalesPlansByCategoryPendingApproval > 0;
	ToDoItem.Presentation  = NStr("vi = 'Kế hoạch bán hàng theo thể loại';
									|ru = 'Планы продаж по категориям';
									|en = 'Sales forecasts by categories'; fa = 'پیش‌بینی‌های فروش بر اساس دسته‌ها';
									|it = 'Piani delle vendite per categorie';
									|pl = 'Plany sprzedaży wg kategorii';
									|tr = 'Kategorilere göre satış tahminleri'");
	ToDoItem.Count     = Result.SalesPlansByCategoryPendingApproval;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "PurchasePlans";
	
	If Result.SalesPlansByCategoryPendingApproval > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
