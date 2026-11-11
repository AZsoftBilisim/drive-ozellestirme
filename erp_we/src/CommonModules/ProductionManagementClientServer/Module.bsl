////////////////////////////////////////////////////////////////////////////////
// Production Management: Contains procedures for production management.
// The module is part of the "Enterprise Management" subsystem.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Stage

// Function for comparing statuses
//
// Parameters:
//  Value1	 - EnumRef.StatusesOfProductionStages2_2 - The first value of the comparison.
//  Value2	 - EnumRef.StatusesOfProductionStages2_2 - The second comparison value.
// 
// Returns:
//   - Number - Result < 0 - the first value is less than the second.
//             Result > 0 - the first value is greater than the second.
//             Result = 0 - the first value is equal to the second.
//
Function ComparisonOfStageStatuses(Value1, Value2) Export
	
	ComparingStatuses = New Map;
	ComparingStatuses.Insert(PredefinedValue("Enum.StatusesOfProductionStages2_2.BeingGenerated"), 0);
	ComparingStatuses.Insert(PredefinedValue("Enum.StatusesOfProductionStages2_2.Generated1"), 1);
	ComparingStatuses.Insert(PredefinedValue("Enum.StatusesOfProductionStages2_2.ForCompletion"), 2);
	ComparingStatuses.Insert(PredefinedValue("Enum.StatusesOfProductionStages2_2.Initiated"),       3);
	ComparingStatuses.Insert(PredefinedValue("Enum.StatusesOfProductionStages2_2.Completed"),    4);
	
	Return ComparingStatuses[Value1] - ComparingStatuses[Value2];
	
EndFunction

// Returns the status of the document, which is available in the operational management stage of production.
//
// Parameters:
//  Parameters	 - FormDataStructure, Structure	 - structure containing the parameters of the division.
//  EnableStatusCompleted - Boolean
// 
// Returns:
//  Array of EnumRef.StatusesOfProductionStages2_2 - array of document statuses.
//
Function StatusesAvailableByOperationalManagement(Parameters, EnableStatusCompleted = True) Export
	
	Result = New Array;
	
	If Parameters.UseManufacturingExecutionSystem Or Parameters.UseShiftTasks Then
		Result.Add(PredefinedValue("Enum.StatusesOfProductionStages2_2.ForCompletion"));
	EndIf;
	
	Result.Add(PredefinedValue("Enum.StatusesOfProductionStages2_2.Initiated"));
	
	If EnableStatusCompleted Then
		Result.Add(PredefinedValue("Enum.StatusesOfProductionStages2_2.Completed"));
	EndIf;
	
	Return Result;
	
EndFunction

// Processing check the placement of the stage in the chart
//
// Parameters:
//  ProductionSchedule - See StructureOfStagePlacementInSchedule
//  Ref - DocumentRef.ProductionStage2_2 - stage of production
//  DataPath - String - data path (the path to the props form)
//  Cancel - Boolean - output parameter.
//
Procedure CheckStagePlacementInSchedule(ProductionSchedule, Ref, DataPath, Cancel) Export
	
	If ProductionSchedule.Begin = '00010101'
		Or ProductionSchedule.Ending = '00010101' Then
		
		MessageText = NStr("vi = 'Lịch biểu sản xuất chưa hoàn thành.';
							|ru = 'График производства не заполнен.';
							|en = 'Production schedule is not filled in.'; fa = 'Production schedule is not filled in.';
							|it = 'Il piano di produzione non è compilato.';
							|pl = 'Harmonogram produkcji nie jest wypełniony.';
							|tr = 'Üretim programı doldurulmadı.'");
		
		CommonClientServer.MessageToUser(
			MessageText, 
			Ref,,
			DataPath,
			Cancel);
			
	ElsIf ProductionSchedule.Begin > ProductionSchedule.Ending Then
		
		MessageText = NStr("vi = 'Lịch biểu sản xuất không được điền chính xác.';
							|ru = 'График производства заполнен не правильно.';
							|en = 'Production schedule is filled in incorrectly.'; fa = 'Production schedule is filled in incorrectly.';
							|it = 'Il piano di produzione è compilato nel modo scorretto.';
							|pl = 'Harmonogram produkcji jest wypełniony prawidłowo.';
							|tr = 'Üretim programı yanlış dolduruldu.'");
		
		CommonClientServer.MessageToUser(
			MessageText, 
			Ref,,
			DataPath,
			Cancel);
		
	EndIf;
	
EndProcedure

// Returns a list of table names that store data about stage output items
//
// Returns:
//   - Array - names of tables storing data about the output products of the stage.
//
Function ProductTableNames() Export
	
	Result = New Array;
	
	Result.Add("ManufacturedProducts");
	Result.Add("SideAndIntermediateRelease");
	Result.Add("BatchFinishedProducts");
	Result.Add("BatchSideAndIntermediateRelease");
	
	Return Result;
	
EndFunction

// Determines whether the passed stage is a production stage
//
// Parameters:
//  Data_Stage - Structure - stage data
//   * Number of the next step.
// 
// Returns:
//  Boolean - True if the passed stage is the releasing one.
//
Function ThisIsAProductionIssueStage(Data_Stage) Export
	
	Return Data_Stage.NextStageNo = 0;
	
EndFunction

// Returns the format for editing stage completion dates.
// 
// Returns:
//  String - Format For Editing Stage Completion Dates
//
Function FormatForEditingStageCompletionDates() Export
	
	EditFormat = "";
	
	
	Return EditFormat;
	
EndFunction
	
#EndRegion

#Region ProductionOperation

// Returns a representation of the operation's unit of measurement
//
// Parameters:
//  UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - unit of measurement for the operation quantity
//  Count		 - Number									 - natural operation meter in physical units of quantity, length, area, volume, and so on.
//  ToReduce		 - Boolean									 - if set to true, then the representation of the unit of measurement will be shortened.
//  LanguageCode		 - String									 - the language code used to output localized strings.
// 
// Returns:
//   - String - representation of the unit of measurement.
//
Function PresentationOfUnitOfOperation(UnitOfMeasure, Count = 0, ToReduce = False, LanguageCode = "") Export
	
	Result = "";
	
	If ValueIsFilled(UnitOfMeasure) Then
		
		Result = String(UnitOfMeasure);
		
	Else
		
		If ToReduce Then
			
			Result = NStr("vi = 'op.';
							|ru = 'оп.';
							|en = 'op.'; fa = 'عمل.';
							|it = 'op.';
							|pl = 'op.';
							|tr = 'işlem'", LanguageCode);
			
		Else
			
			Result = TMCommonUseClientServer.DeclensionOfWord(Count,
																		NStr("vi = 'thao tác, thao tác, thao tác, d';
																			|ru = 'операция, операции, операций, ж';
																			|en = 'operation, operations'; fa = 'operation, operations';
																			|it = 'операция, операции, операций, ж';
																			|pl = 'operation, operations';
																			|tr = 'işlem, işlemler, işlemler, j'", LanguageCode));
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region SchedulePlanning

// Defines the settings for displaying the Gantt chart scale for an adequate representation
// of the chart in the all-Data mode (the Gantt scale Support property).
//
// Parameters:
//  Begin				 - Date - start of the displayed interval.
//  Ending			 - Date - end of the displayed interval.
//  NumberOfIntervals_ - Number - the number of intervals displayed on the chart.
// 
// Returns:
//  Structure - display settings.
//
Function GanttChartScaleSettingsInAllDataMode(Begin, Ending, NumberOfIntervals_) Export
	
	DifferenceHours = Round((EndOfHour(Ending)-BegOfHour(Begin))/(60*60));
	DifferenceDays = Round((EndOfDay(Ending)-BegOfDay(Begin))/(60*60*24));
	WeekDifference = Round((EndOfWeek(Ending)-BegOfWeek(Begin))/(60*60*24*7));
	DifferenceIsMonths = Round((EndOfMonth(Ending)-BegOfMonth(Begin))/(60*60*24*30));
	DifferenceQuarters = Round((EndOfQuarter(Ending)-BegOfQuarter(Begin))/(60*60*24*30*3));
	
	If DifferenceHours <= NumberOfIntervals_ Then
		
		Unit = TimeScaleUnitType.Hour;
		Format = "DF='dd.MM HH:mm'";
		BeginOfWholeInterval = BegOfHour(Begin);
		EndOfFullInterval = EndOfHour(Ending);
		
	ElsIf DifferenceDays <= NumberOfIntervals_ Then
		
		Unit = TimeScaleUnitType.Day;
		Format = "DLF=D";
		BeginOfWholeInterval = BegOfDay(Begin);
		EndOfFullInterval = EndOfDay(Ending);
		
	ElsIf WeekDifference <= NumberOfIntervals_ Then
		
		Unit = TimeScaleUnitType.Week;
		Format = "DLF=D";
		BeginOfWholeInterval = BegOfWeek(Begin);
		EndOfFullInterval = EndOfWeek(Ending);
		
	ElsIf DifferenceIsMonths <= NumberOfIntervals_ Then
		
		Unit = TimeScaleUnitType.Month;
		Format = "DF='MMMM yyyy'";
		BeginOfWholeInterval = BegOfMonth(Begin);
		EndOfFullInterval = EndOfMonth(Ending);
		
	ElsIf DifferenceQuarters <= NumberOfIntervals_ Then
		
		Unit = TimeScaleUnitType.Quarter;
		
		TemplateFormat = "DF='q ""%1"" yyyy'";
		Format = StrTemplate(TemplateFormat, NStr("vi = 'căn hộ';
													|ru = 'кв.';
													|en = 'qtr.'; fa = 'qtr.';
													|it = 'appartamento';
													|pl = 'kw.';
													|tr = 'çeyrek'"));
		
		BeginOfWholeInterval = BegOfQuarter(Begin);
		EndOfFullInterval = EndOfQuarter(Ending);
		
	Else
		
		Unit = TimeScaleUnitType.Year;
		
		TemplateFormat = "DF='yyyy ""%1""'";
		Format = StrTemplate(TemplateFormat, NStr("vi = 'năm';
													|ru = 'г.';
													|en = 'year'; fa = 'سال';
													|it = 'anno';
													|pl = 'r.';
													|tr = 'yıl'"));
		
		BeginOfWholeInterval = BegOfYear(Begin);
		EndOfFullInterval = EndOfYear(Ending);
		
	EndIf;
	
	Result = New Structure;
	Result.Insert("Unit", Unit);
	Result.Insert("Format", Format);
	Result.Insert("BeginOfWholeInterval", BeginOfWholeInterval);
	Result.Insert("EndOfFullInterval", EndOfFullInterval);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

// Sets the type of the input field that contains the contractor's work.
//
// Parameters:
//  Performer							 - DefinedType.WorkAssignee - value of the input field.
//  UseTeamWorkOrders			 - Boolean - parameter of the production division.
//  AccountingForLaborCostsByEmployees	 - Boolean
//
Procedure SetArtistType(Performer, UseTeamWorkOrders, AccountingForLaborCostsByEmployees) Export
	
	If Performer <> Undefined Then
		Return;
	EndIf;
	
	If UseTeamWorkOrders Then
		Performer = PredefinedValue("Catalog.Teams.EmptyRef");
	Else
		Performer = PredefinedValue("Catalog.Persons.EmptyRef");
	EndIf;
	
EndProcedure

// Returns the parameters required to perform the "fill in the replay" action.
//
// Parameters:
//  ActualProductionDate	 - Date - the actual date of production
//  PlannedProductionDate	 - Date - planned production date.
// 
// Returns:
//  Structure - list of parameters.
//
Function ActionParametersFillProductionDate(ActualProductionDate = '00010101', PlannedProductionDate = '00010101') Export
	
	ActionParameters = New Structure("ActualProductionDate, PlannedProductionDate", ActualProductionDate, PlannedProductionDate);
	
	Return ActionParameters;
	
EndFunction

// Adds a quality control action to the action structure, depending on the name of the table part.
//
// Parameters:
//   TSName - String - Name of the tabular part for which the check is performed
//   StructureOfActions - Structure - The structure to which the action is added
//   CacheQualityControl - See QualityControl.DataCacheOfMechanism
//
Procedure AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl) Export
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region EditingProductionStage

#Region Other

// Contains General actions that are performed when the item is changed in a stage or in an order to the processor 
// IMPORTANT: there must be actions that are allowed for both the stage and the order to the processor.
//
Procedure AddActionsToStructureWhenChangingProducts(TSName,
															Form,
															Object,
															StructureOfActions,
															AdditionalParameters = Undefined,
															AddActionsForFormAttributes = True) Export
	
	If AddActionsForFormAttributes Then
		
		StructureOfActions.Insert("CheckCharacteristicsByOwner",);
		StructureOfActions.Insert("CheckFillPackageByOwner");
		
		StructureOfActions.Insert(
			"FillInProductTypeAttribute_",
			New Structure("Products", "ItemsType"));
		
		StructureOfActions.Insert(
			"FillInArticleAttribute",
			New Structure("Products", "SKU"));
		
		StructureOfActions.Insert(
			"ProductsOnChangeOverridable",
			New Structure("FormName, TabularSectionName", Form.FormName, TSName));
		
	EndIf;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	If TSName = "SupplyWithMaterialsAndWorks"
		Or TSName = "EditStagesSupplyWithMaterialsAndLabor" Then
	
		SeriesSpecificationParameters = Form[Form.StageEditingParameters.PropsNameParametersForSpecifyingSeries][TSName];
		
		MethodParameters = New Structure();
		MethodParameters.Insert("ProductionOrder",           Object.ReferenceOrder);
		MethodParameters.Insert("Department",                 Object.Department);
		MethodParameters.Insert("Ref",                        Object.Ref);
		MethodParameters.Insert("Status",                        Object.Status);
		MethodParameters.Insert("SubcontractOrder",            Object.SubcontractOrder);
		MethodParameters.Insert("SeriesSpecificationParameters",        SeriesSpecificationParameters);
		MethodParameters.Insert("Form",                         Form);
		MethodParameters.Insert("FillInSecurityOption", True);
		MethodParameters.Insert("FillInTheWarehouse", True);
		MethodParameters.Insert("FillInSeparately", True);
		MethodParameters.Insert("FillInOnlyEmpty", False);
		MethodParameters.Insert("WarehouseOnlyHasItsOwnShopFloorStockroom", False);
		MethodParameters.Insert("SupplyOption");
		MethodParameters.Insert("Warehouse");
		MethodParameters.Insert("WithAssignment");
		
		If ValueIsFilled(AdditionalParameters) Then
			FillPropertyValues(MethodParameters, AdditionalParameters);
		EndIf;
		
		AddToStructureActionsCheckSoftwareInProductionPhase(
			StructureOfActions,
			MethodParameters,
			AddActionsForFormAttributes);
		
	ElsIf TSName = "UnusedMaterials" Then
		
		ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(Object.Department, StructureOfActions, "Recipient");
		
	EndIf;
	
EndProcedure

Procedure AddToStructureActionsCheckSoftwareInProductionPhase(
			StructureOfActions,
			Parameters,
			AddActionsForFormAttributes = True) Export
	
	ActionParameters = New Structure;
	ActionParameters.Insert("ProductionOrder");
	
	// Enable/disable filling in the corresponding Attributes.
	ActionParameters.Insert("FillInSecurityOption", True);
	ActionParameters.Insert("FillInTheWarehouse", True);
	ActionParameters.Insert("FillInSeparately", True);
	
	// Special mode - the Attributes of the Support option and Warehouse are filled in according to the settings only if the Attribute
	// in the line is empty. If the Attribute in the line is filled in, then the same value remains.
	// Does not affect filling in the Attributes Separately.
	ActionParameters.Insert("FillInOnlyEmpty", False);
	
	// Special mode - the warehouse will be filled only if it is a shop floor stockroom of the Cur division
	ActionParameters.Insert("WarehouseOnlyHasItsOwnShopFloorStockroom", False);
	
	// Constants - when filled in, all lines will receive this value.
	ActionParameters.Insert("SupplyOption");
	ActionParameters.Insert("Warehouse");
	ActionParameters.Insert("WithAssignment");
	
	FillPropertyValues(ActionParameters, Parameters);
	
	StructureOfActions.Insert("CheckSoftwareInProductionPhase", ActionParameters);
	
	//
	
	StructureOfActions.Insert("FillInAssignmentInProductionPhase");
	
	//
	
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters", Parameters.SeriesSpecificationParameters);
	
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	//
	
	If AddActionsForFormAttributes Then
		
		DocumentParameters = New Structure();
		DocumentParameters.Insert("Form", Parameters.Form);
		
		ProvisionInDocumentsClientServer.AddCollateralActions(
			StructureOfActions,
			"WarehouseIsRequired,DateOfShipmentRequired_",
			DocumentParameters);
		
		StructureOfActions.Insert("FillInShopPantryAttribute");
		
	EndIf;
	
EndProcedure

Function ParametersForFillingIssuePrices(PriceKind, Currency, Date = '00010101') Export
	
	PriceFillingStructure = New Structure("PriceKind,Currency,Date", PriceKind, Currency, Date);
	Return PriceFillingStructure;
	
EndFunction

Procedure AddActionsToStructureFillInAvailableColumn(StructureOfActions, Parameters, CurrentRow) Export
	
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"AvailableInOtherLines",
		Parameters);
		
EndProcedure

#EndRegion

#EndRegion

#Region Stage

// Returns the parameters required to fill in the specification in the line
// 
// Returns:
// 	Structure
//
Function ParametersForFillingInSpecificationInLine() Export

	Return New Structure("Department,Date");

EndFunction

Function ReleaseDirectionSelectionList(CurrentData, Form) Export
	
	Result = New ValueList;
	
	If CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		Result.Add(
			PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToBusinessUnit"),
			NStr("vi = 'Sang bộ phận';
				|ru = 'В подразделение';
				|en = 'To business unit'; fa = 'To business unit';
				|it = 'Al reparto';
				|pl = 'Do działu';
				|tr = 'Departmana'"));
	Else
		Result.Add(
			PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse"),
			NStr("vi = 'Điều chuyển hàng hóa';
				|ru = 'На склад';
				|en = 'To warehouse'; fa = 'To warehouse';
				|it = 'Al magazzino';
				|pl = 'Na magazyn';
				|tr = 'Ambara'"));
	EndIf;
	
	If Form.UseWriteOffForExpenses
		And (CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
				And CommonClientServer.HasAttributeOrObjectProperty(Form, "ProductionByThirdPartyIsUsed")
				And Form.ProductionByThirdPartyIsUsed
			Or CommonClientServer.HasAttributeOrObjectProperty(Form, "UseSubcontractOrders2_5")
				And Form.UseSubcontractOrders2_5
			Or Not CommonClientServer.HasAttributeOrObjectProperty(Form.Object, "ProductionByThirdParty")
			Or Not Form.Object.ProductionByThirdParty) Then
			
		Result.Add(
			PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand"),
			NStr("vi = 'Ghi giảm vào chi phí';
				|ru = 'Списать на расходы';
				|en = 'Expense as'; fa = 'هزینه به عنوان';
				|it = 'Stornare sulle spese';
				|pl = 'Spisać w koszty';
				|tr = 'Gider olarak kaydet'"));
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region DataStructures

Function ProductionOperationKey(Advanced = False) Export
	
	Result = New Structure;
	
	Result.Insert("Stage");
	Result.Insert("Operation");
	Result.Insert("OperationID");
	
	If Advanced Then
		Result.Insert("Department");
		Result.Insert("State");
		Result.Insert("ProductionOperation");
	EndIf;
	
	Return Result;
	
EndFunction

Function BufferStructure() Export
	
	UnitOfMeasurementDay = PredefinedValue("Enum.TimeMeasureUnits.Day");
	
	Result = New Structure;
	
	Result.Insert("PreliminaryBuffer", 0);
	Result.Insert("UnitOfMeasureOfPreliminaryBuffer", UnitOfMeasurementDay);
	Result.Insert("FollowUpBuffer", 0);
	Result.Insert("UnitOfMeasureOfFollowUpBuffer", UnitOfMeasurementDay);
	
	Return Result;
	
EndFunction

Function BufferCalculationStructure() Export
	
	Buffer = New Structure(
		"Duration,
		|UnitOfMeasure,
		|Date,
		|DirectPlacement,
		|PlacementDate");
	
	Return Buffer;

EndFunction

// The structure of the stage placement in the schedule.
// 
// Returns:
//  Structure - The Structure Of The Stage Placement In The Schedule:
// * Calculated - Boolean - 
// * Begin - Date - 
// * PreliminaryBufferEnd - Date - 
// * FollowUpBufferStart - Date - 
// * Ending - Date - 
Function StructureOfStagePlacementInSchedule() Export
	
	Result = New Structure();
	
	Result.Insert("Calculated", False);
	
	Result.Insert("Begin", '00010101');
	Result.Insert("PreliminaryBufferEnd", '00010101');
	Result.Insert("FollowUpBufferStart", '00010101');
	Result.Insert("Ending", '00010101');
	
	Return Result;
	
EndFunction

Function OrderProductionStructure() Export
	
	Result = New Structure(
		"Products,
		|Characteristic,
		|Purpose,
		|BillOfMaterials,
		|Warehouse,
		|Department,
		|Package,
		|Count,
		|NumberOfPackages");
	
	Return Result;

EndFunction

Function SpecificationReplacementStructure() Export
	
	Result = New Structure("OrderDocument,LineNumber,BillOfMaterials,NewSpecification");
	Return Result;
	
EndFunction

// Returns the data of the finishedproduct being repaired from the document data
//
// Parameters:
//  The current data	 is a document object.Custom PRODUCTION2_2	 - production order
// 
// Returns:
//  Structure - data of the finishedproduct being repaired
//
Function DataOfFinishedProductBeingRepairedByStructure(Object = Undefined) Export
	
	Var_Key = "Products,Characteristic,Purpose,Count,Series,BatchesIndicationStatus,ItemVariantsAreUsed,ItemsType,LineNumber";
	
	StringStructure = New Structure(Var_Key);
	
	If Not Object = Undefined Then
		
		FillPropertyValues(StringStructure, Object);
		
		StringStructure.Products        = Object.UnderRepairProduct;
		StringStructure.Characteristic      = Object.UnderRepairVariant;
		StringStructure.Series               = Object.UnderRepairBatch;
		StringStructure.BatchesIndicationStatus = Object.UnderRepairBatchSpecificationStatus;
		
		StringStructure.Purpose  = PredefinedValue("Catalog.Assignments.EmptyRef");
		StringStructure.LineNumber = 1;
		StringStructure.Count  = 1;
		
	EndIf;
	
	Return StringStructure;
	
EndFunction

// Returns data line tab. Supply parts of the row data
//
// Parameters:
//  CurrentData - FormDataCollectionItem
// 
// Returns:
//  Structure - data of the finishedproduct being repaired
//
Function TheseLinesSupplyOfMaterialsAndWorksStructure(CurrentData = Undefined) Export
	
	Keys = "Products,Characteristic,Purpose,Series,Count,BatchesIndicationStatus,BatchesIndicationStatusSender,BatchesIndicationStatusRecipient,Canceled,
		|ItemsType,ItemVariantsAreUsed,NumberOfPackages,Package,BillOfMaterials,
		|UnderRepairProduct,UnderRepairVariant,UnderRepairBatch,UnderRepairBatchSpecificationStatus,
		|FinishedProductBeingRepairedCharacteristicsAreUsed,RepairedFinishedProductTypeOfItem";
	
	RowData = New Structure(Keys);
	
	If CurrentData <> Undefined Then
		FillPropertyValues(RowData, CurrentData);
	EndIf;
	
	Return RowData;
	
EndFunction

#EndRegion

#Region Other

Function EventNameUpdateStageDispatching() Export
	
	Return "UpdateStageDispatching";
	
EndFunction

Function ArrayOfValues(Value, CreateNewArray = False) Export

	Var Result;
	
	If TypeOf(Value) <> Type("Array") Then
		
		Result = New Array;
		
		If Value <> Undefined Then
			Result.Add(Value);
		EndIf;
		
	ElsIf CreateNewArray Then
		
		Result = New Array;
		For Each CollectionItem In Value Do
			Result.Add(CollectionItem);
		EndDo;
		
	Else
		
		Result = Value;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function DescriptionOfSchedulingSettings(FullReplanning, CancelManualChangesOfSchedule) Export
	
	If FullReplanning And CancelManualChangesOfSchedule Then
		
		Result = NStr("vi = 'Lập kế hoạch một lịch trình cho tất cả các kỳ sản xuất. Thay đổi lịch trình thủ công sẽ bị hủy bỏ.';
						|ru = 'Планировать график всех этапов производства. Ручные изменения графика будут отменены.';
						|en = 'Plan the schedule for all production stages. Manual changes will be canceled.'; fa = 'Plan the schedule for all production stages. Manual changes will be canceled.';
						|it = 'Programmare il piano di tutte le fasi della produzione. Le modifiche manuali del piano verranno cancellate.';
						|pl = 'Zaplanować harmonogram wszystkich etapów produkcji. Ręczne zmiany harmonogramu zostaną anulowane.';
						|tr = 'Üretimin tüm aşamalarının programını planla. Manuel program değişiklikleri iptal edilecektir.'");
		
	ElsIf FullReplanning And Not CancelManualChangesOfSchedule Then
		
		Result = NStr("vi = 'Lập kế hoạch lịch trình cho tất cả các kỳ sản xuất, không bao gồm các kỳ được đặt thủ công.';
						|ru = 'Планировать график всех этапов производства, исключая размещенные вручную этапы.';
						|en = 'Plan the schedule for all production stages except for stages placed manually.'; fa = 'Plan the schedule for all production stages except for stages placed manually.';
						|it = 'Programmare il piano di tutte le fasi della produzione, eccetto le fasi inserite manualmente.';
						|pl = 'Zaplanować harmonogram wszystkich etapów produkcji, z wyłączeniem umieszczonych ręcznie etapów.';
						|tr = 'Manuel olarak yapılan aşamalar hariç, üretimin tüm aşamalarının programını planla.'");
		
	ElsIf Not FullReplanning And CancelManualChangesOfSchedule Then
		
		Result = NStr("vi = 'Lập kế hoạch lịch trình các bước yêu cầu kể lại. Thay đổi lịch trình thủ công sẽ bị hủy bỏ.';
						|ru = 'Планировать график этапов, требующих пересчета. Ручные изменения графика будут отменены.';
						|en = 'Plan the schedule of stages that require rescheduling. Manual changes will be canceled.'; fa = 'Plan the schedule of stages that require rescheduling. Manual changes will be canceled.';
						|it = 'Programmare il piano delle fasi, per le quali è richiesto il ricalcolo. Le modifiche del piano effettuate manualmente verranno cancellate.';
						|pl = 'Zaplanować harmonogram etapów, które wymagają przeliczenia. Ręczne zmiany harmonogramu zostaną anulowane.';
						|tr = 'Yeniden hesaplama gerektiren aşama programını planla. Manuel program değişiklikleri iptal edilecektir.'");
		
	Else
		
		Result = NStr("vi = 'Lập kế hoạch lịch trình các bước yêu cầu kể lại, ngoại trừ các bước được đặt thủ công.';
						|ru = 'Планировать график этапов, требующих пересчета, исключая размещенные вручную этапы.';
						|en = 'Plan the schedule of all stages that require rescheduling except for stages placed manually.'; fa = 'Plan the schedule of all stages that require rescheduling except for stages placed manually.';
						|it = 'Programmare il piano delle fasi, per le quali è richiesto il ricalcolo, eccetto le fasi inserite manualmente.';
						|pl = 'Zaplanować harmonogram etapów, które wymagają przeliczenia, z wyłączeniem umieszczonych ręcznie etapów.';
						|tr = 'Manuel olarak yapılan aşamalar hariç, yeniden hesaplama gerektiren aşama programını planla.'");
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ShiftTaskPresentation_(Shift, Date, ProductionArea, SeveralShiftsInDepartment) Export
	
	If SeveralShiftsInDepartment Then
		
		Return Format(Date, "DLF=D") + " " + Shift + ?(ValueIsFilled(ProductionArea), ", " + ProductionArea, "");
		
	Else
		
		Return Format(Date, "DLF=D") + ?(ValueIsFilled(ProductionArea), ", " + ProductionArea, "");
		
	EndIf;
	
EndFunction

// Returns the duration of the work schedule interval in seconds.
// The start and end times should be within two days.
// 
// Parameters:
//  BeginTime - Date - The beginning of the interval.
//  EndTime - Date - The end of the interval.
// 
// Returns:
//  Number
//
Function DurationOfScheduleInterval(BeginTime, EndTime) Export
	
	Duration = 0;
	
	If BeginTime = EndTime Then
		Duration = 86400;
	ElsIf BeginTime < EndTime
		And EndTime <> '000101012359'
		And EndTime <> '00010101235959' Then
		Duration = EndTime - BeginTime;
	ElsIf Not ValueIsFilled(EndTime)
		Or EndTime = '000101012359'
		Or EndTime = '00010101235959' Then
		Duration = EndOfDay(EndTime) - BeginTime + 1;
	Else
		IsMainPart = EndOfDay(BeginTime) - BeginTime + 1;
		RollingPart = EndTime - BegOfDay(EndTime);
		Duration = IsMainPart + RollingPart;
	EndIf;
	
	Return Duration;
	
EndFunction

#EndRegion

#EndRegion
