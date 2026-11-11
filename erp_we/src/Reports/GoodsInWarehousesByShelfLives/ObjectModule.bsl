#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	QuerySchema = GetTemplate("RequestRemainingGoodsByShelfLifeReferenceRecords");
	
	QueryText = QuerySchema.DataSets.SetOfPossibleSeries.Query;
	QueryText = StrReplace(QueryText,
								"&QueryTextItemWeight",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
									"ProductStockBalance.Products.UnitOfMeasure",
									"ProductStockBalance.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextTheVolumeOfTheItem",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
									"ProductStockBalance.Products.UnitOfMeasure",
									"ProductStockBalance.Products"));
	
	QuerySchema.DataSets.SetOfPossibleSeries.Query = QueryText;
	
	MainSchema				= GetTemplate("MainDataCompositionSchema");
	SeriesRemainsAndSeriesReference	= MainSchema.DataSets.SeriesRemainsAndSeriesReference; // DataCompositionSchemaDataSetUnion
	
	QueryText = SeriesRemainsAndSeriesReference.Items.RequestForBalances.Query;
	QueryText = StrReplace(QueryText,
								"&QueryTextItemWeight",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
									"ProductStockBalance.Products.UnitOfMeasure",
									"ProductStockBalance.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextTheVolumeOfTheItem",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
									"ProductStockBalance.Products.UnitOfMeasure",
									"ProductStockBalance.Products"));
	
	SeriesRemainsAndSeriesReference.Items.RequestForBalances.Query = QueryText;
	
	RequestSettings		= QuerySchema.DefaultSettings;
	MainCircuitSettings	= SettingsComposer.GetSettings();
	
	DataCompositionClientServer.SetParameter(MainCircuitSettings, "LineNotUsable", NStr("vi = 'Không dùng được';
																						|ru = 'Не годен';
																						|en = 'Not usable'; fa = 'غیرقابل استفاده';
																						|it = 'Non idoneo';
																						|pl = 'Nie nadaje się';
																						|tr = 'Geçerli değil'"));
	DataCompositionClientServer.SetParameter(MainCircuitSettings, "StringIsNotLimited", NStr("vi = 'Không hạn chế';
																							|ru = 'Не ограничен';
																							|en = 'Unrestricted'; fa = 'نامحدود';
																							|it = 'Non limitato';
																							|pl = 'Nieograniczony';
																							|tr = 'Sınırsız'"));
	
	DataCompositionClientServer.CopyDataCompositionFilter(QuerySchema, RequestSettings, MainCircuitSettings);
	DataCompositionClientServer.FillInElements(RequestSettings.DataParameters,
													MainCircuitSettings.DataParameters);
	
	WarehouseOperationsOfGoodsAcceptance = Enums.WarehouseTransactions.WarehouseOperationsOfGoodsAcceptance();
	WarehouseOperationsOfGoodsAcceptance.Add(Enums.WarehouseTransactions.ShipmentByTransfer);
	WarehouseOperationsOfGoodsAcceptance.Add(Enums.WarehouseTransactions.SurplusesRecord);
	WarehouseOperationsOfGoodsAcceptance.Add(Enums.WarehouseTransactions.TransferToProductionShipment);
	WarehouseOperationsOfGoodsAcceptance.Add(Enums.WarehouseTransactions.TransferBetweenWarerooms);
	
	DataCompositionClientServer.SetParameter(RequestSettings,
													"WarehouseOperationsOfGoodsAcceptance",
													WarehouseOperationsOfGoodsAcceptance,
													True);
	
	ProcessingTree		= New ValueTree;
	TemplateComposer	= New DataCompositionTemplateComposer;
	CompositionTemplate		= TemplateComposer.Execute(QuerySchema,
														RequestSettings,
														,
														,
														Type("DataCompositionValueCollectionTemplateGenerator"));
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.ShowOutputPercent = True;
	OutputProcessor.SetObject(ProcessingTree);
	OutputProcessor.Output(DataCompositionProcessor, True);
	
	NumberType					= New TypeDescription("Number", New NumberQualifiers(15, 3));
	TypeOfFeature			= New TypeDescription("CatalogRef.ItemsCharacteristics");
	PackageTypeUnits	= New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure");
	TypeExpirationDate				= New TypeDescription("Number", New NumberQualifiers(15, 0));
	TimeUnitType	= New TypeDescription("EnumRef.TimeMeasureUnits");
	
	RemnantsOfSeriesForReference = New ValueTable;
	RemnantsOfSeriesForReference.Columns.Add("Warehouse",							New TypeDescription("CatalogRef.Warehouses"));
	RemnantsOfSeriesForReference.Columns.Add("Premise",						New TypeDescription("CatalogRef.Warerooms"));
	RemnantsOfSeriesForReference.Columns.Add("Products",					New TypeDescription("CatalogRef.Products"));
	RemnantsOfSeriesForReference.Columns.Add("ProductsWeight",				NumberType);
	RemnantsOfSeriesForReference.Columns.Add("ProductsVolume",				NumberType);
	RemnantsOfSeriesForReference.Columns.Add("Characteristic",				TypeOfFeature);
	RemnantsOfSeriesForReference.Columns.Add("Purpose",					New TypeDescription("CatalogRef.Assignments"));
	RemnantsOfSeriesForReference.Columns.Add("ControlledLotReference",			New TypeDescription("CatalogRef.ControlledLots"));
	RemnantsOfSeriesForReference.Columns.Add("Series",							New TypeDescription("CatalogRef.ItemsBatches"));
	RemnantsOfSeriesForReference.Columns.Add("ExpirationDate_",					TypeExpirationDate);
	RemnantsOfSeriesForReference.Columns.Add("SpecifyExpirationToThePrecisionOfTheHour", New TypeDescription("Boolean"));
	RemnantsOfSeriesForReference.Columns.Add("ShelfLifeUnitOfMeasure",	TimeUnitType);
	RemnantsOfSeriesForReference.Columns.Add("ValidUntil_",						New TypeDescription("Date"));
	RemnantsOfSeriesForReference.Columns.Add("Balance",						NumberType);
	RemnantsOfSeriesForReference.Columns.Add("StorageUnit",				PackageTypeUnits);
	RemnantsOfSeriesForReference.Columns.Add("UnitForReports",				PackageTypeUnits);
	RemnantsOfSeriesForReference.Columns.Add("UnitFactorForReports",	NumberType);
	
	RemainingFinishedGoodsOnThePeriodStart		= CompositionTemplate.ParameterValues.Find("RemainingFinishedGoodsOnThePeriodStart");
	RemainingFinishedGoodsOnThePeriodEnd	= CompositionTemplate.ParameterValues.Find("RemainingFinishedGoodsOnThePeriodEnd");
	
	SelectionAtBeginningOfOGPeriod		= RemainingFinishedGoodsOnThePeriodStart <> Undefined
									And TypeOf(RemainingFinishedGoodsOnThePeriodStart.Value) = Type("Date")
									And ValueIsFilled(RemainingFinishedGoodsOnThePeriodStart.Value);
	SelectionAtEndOfOGPeriod	= RemainingFinishedGoodsOnThePeriodEnd <> Undefined
									And TypeOf(RemainingFinishedGoodsOnThePeriodEnd.Value) = Type("Date")
									And ValueIsFilled(RemainingFinishedGoodsOnThePeriodEnd.Value);
	
	RemainingFinishedGoodsOnThePeriodStart		= ?(SelectionAtBeginningOfOGPeriod, RemainingFinishedGoodsOnThePeriodStart.Value, Date(1,1,1));
	RemainingFinishedGoodsOnThePeriodEnd	= ?(SelectionAtEndOfOGPeriod, RemainingFinishedGoodsOnThePeriodEnd.Value, Date(1,1,1));
	
	UseUnitsOfMeasureForReports = GetFunctionalOption("UseUnitsOfMeasureForReports");
	
	For Each RowProducts_ In ProcessingTree.Rows Do
		
		CurrentRow		= Undefined;
		GoodsQuantity	= RowProducts_.InStockBalance;
		
		For Each RowOfExpirationDate In RowProducts_.Rows Do
			
			If (SelectionAtBeginningOfOGPeriod
					And RowOfExpirationDate.ValidUntilAutoSettlement < RemainingFinishedGoodsOnThePeriodStart)
				Or (SelectionAtEndOfOGPeriod
					And RowOfExpirationDate.ValidUntilAutoSettlement > RemainingFinishedGoodsOnThePeriodEnd) Then
				
				GoodsQuantity = GoodsQuantity - Min(GoodsQuantity, RowOfExpirationDate.QuantitySeries);
				
				If GoodsQuantity <= 0 Then
					Break;
				EndIf;
				
				Continue;
				
			EndIf;
			
			AmountOfRemainder = Min(GoodsQuantity, RowOfExpirationDate.QuantitySeries);
			
			If CurrentRow = Undefined
				Or (CurrentRow <> Undefined
					And CurrentRow.Series <> RowOfExpirationDate.SeriesAutomaticCalculation) Then
				
				NewDataLine = RemnantsOfSeriesForReference.Add();
				FillPropertyValues(NewDataLine, RowOfExpirationDate);
				
				NewDataLine.ProductsWeight = RowOfExpirationDate.ProductsWeightAutoCalculation;
				NewDataLine.ProductsVolume = RowOfExpirationDate.ProductsVolumeAutoCalculation;
				NewDataLine.Series = RowOfExpirationDate.SeriesAutomaticCalculation;
				NewDataLine.ExpirationDate_ = RowOfExpirationDate.ExpirationDateAutoCalculation;
				NewDataLine.SpecifyExpirationToThePrecisionOfTheHour = RowOfExpirationDate.SpecifyExpirationDateUpToHoursAutoCalculation;
				NewDataLine.ShelfLifeUnitOfMeasure = RowOfExpirationDate.UnitOfMeasurementOfExpirationDateAutoCalculation;
				NewDataLine.ValidUntil_ = RowOfExpirationDate.ValidUntilAutoSettlement;
				NewDataLine.Balance = AmountOfRemainder;
				NewDataLine.StorageUnit = RowOfExpirationDate.StorageUnitAutoCalculation;
				
				If UseUnitsOfMeasureForReports Then
					NewDataLine.UnitForReports = RowOfExpirationDate.UnitForAutoCalculationReports;
					NewDataLine.UnitFactorForReports = RowOfExpirationDate.UnitFactorForAutoCalculationReports;
				EndIf;
				
				CurrentRow = NewDataLine;
				
			Else
				CurrentRow.Balance = CurrentRow.Balance + AmountOfRemainder;
			EndIf;
			
			GoodsQuantity = GoodsQuantity - AmountOfRemainder;
			
			If GoodsQuantity <= 0 Then
				Break;
			EndIf;
			
		EndDo;
		
		If GoodsQuantity <> 0
			And Not SelectionAtBeginningOfOGPeriod Then
			
			NewDataLine = RemnantsOfSeriesForReference.Add();
			FillPropertyValues(NewDataLine, RowProducts_);
			
			NewDataLine.ProductsWeight = RowProducts_.ProductsWeightAutoCalculation;
			NewDataLine.ProductsVolume = RowProducts_.ProductsVolumeAutoCalculation;
			NewDataLine.Series = RowProducts_.SeriesAutomaticCalculation;
			NewDataLine.ExpirationDate_ = RowProducts_.ExpirationDateAutoCalculation;
			NewDataLine.SpecifyExpirationToThePrecisionOfTheHour = RowProducts_.SpecifyExpirationDateUpToHoursAutoCalculation;
			NewDataLine.ShelfLifeUnitOfMeasure = RowProducts_.UnitOfMeasurementOfExpirationDateAutoCalculation;
			NewDataLine.ValidUntil_ = RowProducts_.ValidUntilAutoSettlement;
			NewDataLine.Balance = GoodsQuantity;
			NewDataLine.StorageUnit = RowProducts_.StorageUnitAutoCalculation;
			
			If UseUnitsOfMeasureForReports Then
				NewDataLine.UnitForReports = RowProducts_.UnitForAutoCalculationReports;
				NewDataLine.UnitFactorForReports = RowProducts_.UnitFactorForAutoCalculationReports;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("RemnantsOfSeriesForReference", RemnantsOfSeriesForReference);
	
	CompositionTemplate = TemplateComposer.Execute(MainSchema, MainCircuitSettings, DetailsData);
	
	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema,
																SettingsComposer,
																ResultDocument,
																AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.AfterQuickSettingsBarFilled = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//	ThisForm - ClientApplicationForm - The Form of the report. Contains including:
//		* Parameters - Structure - The parameter structure contains, among other things:
//			** CommandDetails - Structure:
//				*** AdditionalParameters - Structure:
//					**** CommandName - String
//	Cancel - Boolean - passed from the handler parameters "as is".
//	StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//	"Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		If Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then
			
			If Parameters.CommandDetails.AdditionalParameters.CommandName = "RemnantsOfProductListByExpirationDate" Then
				ThisForm.ParametersForm.Filter.Insert("Products", Parameters.CommandParameter);
			EndIf;
			
		Else
			ThisForm.ParametersForm.Filter.Insert("InventoryRecount", Parameters.CommandParameter);
		EndIf;
		
	EndIf;
	
EndProcedure

// See ReportsOverridable.BeforeLoadVariantAtServer.
//
// Parameters:
//	ThisForm - ClientApplicationForm - report form.
//	NewDCSettings - DataCompositionSettings - Customize the layout of the data.
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

// Called in the report form handler of the same name after executing the form code.
// More detailed See ReportsClientServer.DefaultReportSettings
// description of the procedure for post-filling the Quick Settings panel.
//
// Parameters:
//	ThisForm - ClientApplicationForm - report form.
//	FillParameters - Structure - Parameters for filling in the quick settings panel.
//
Procedure AfterQuickSettingsBarFilled(ThisForm, FillParameters) Export
	
	// Optimization of the relative location of the selection and the parameters of the expiration period.
	FormItems = ThisForm.Items;

	If FormItems.Find("TimeIntervals") <> Undefined
		And FormItems.TimeIntervals.ChildItems.Count() Then
		
		StructureExpirationDate = FindFormElementBySelectionPresentation(ThisForm,
																				"From1 expiring term_ ofexpirationdates",
																				True);
		
		If StructureExpirationDate <> Undefined Then
			
			If StructureExpirationDate.SelectionGroupUse <> Undefined Then
				FormItems.Move(StructureExpirationDate.SelectionGroupUse,
											FormItems.TimeIntervals,
											FormItems.TimeIntervals.ChildItems[0]);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;

EndFunction

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer,
																				"QuantityUnits");
	EndIf;
	
EndProcedure

Function FindFormElementBySelectionPresentation(ThisForm, FilterPresentation, SearchForGroup = False)
	
	DataCompositionSettings	= ThisForm.Report.SettingsComposer.Settings; // DataCompositionSettings
	FoundSelection				= Undefined;
	
	For Each FilterElement In DataCompositionSettings.Filter.Items Do
		
		If FilterElement.Presentation = FilterPresentation Then
			FoundSelection = FilterElement;
			
			Break;
		EndIf;
		
	EndDo;
	
	DesiredElement = Undefined;
	
	If FoundSelection <> Undefined Then
		
		UserSettingID = FoundSelection.UserSettingID;
		
		If Not IsBlankString(UserSettingID) Then
			
			DesiredElement		= New Structure;
			FormItems		= ThisForm.Items;
			IDParameterString	= StrReplace(UserSettingID, "-", "");
			
			If SearchForGroup Then
				DesiredElement.Insert("FilterGroup",
										FormItems.Find("FilterGroup_" + IDParameterString));
				DesiredElement.Insert("SelectionGroupUse",
										FormItems.Find("SelectionGroup_Usage_" + IDParameterString));
				DesiredElement.Insert("SelectionPanelGroup",
										FormItems.Find("SelectionPanelGroup_" + IDParameterString));
			Else
				DesiredElement.Insert("Filter",
										FormItems.Find("Filter_" + IDParameterString));
				DesiredElement.Insert("UsingSelection",
										FormItems.Find("UsingSelection_" + IDParameterString));
				DesiredElement.Insert("FilterValue",
										FormItems.Find("Selection_Value_" + IDParameterString));
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return DesiredElement;
	
EndFunction

#EndRegion

#EndIf
