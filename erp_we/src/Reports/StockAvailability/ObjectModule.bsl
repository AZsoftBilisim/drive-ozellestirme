#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SearchValue = New DataCompositionParameter("RowNow");
	DataParametersElement = SettingsComposer.Settings.DataParameters.FindParameterValue(SearchValue);
	DataParametersElement.Value = NStr("vi = 'Có sẵn';
										|ru = 'В наличии';
										|en = 'In stock'; fa = 'موجود در انبار';
										|it = 'In disposizione';
										|pl = 'Dostępny towar';
										|tr = 'Stokta'");
	
	SearchValue = New DataCompositionParameter("LineQualityControlIsOffNow");
	DataParametersElement = SettingsComposer.Settings.DataParameters.FindParameterValue(SearchValue);
	DataParametersElement.Value = NStr("vi = 'Có sẵn';
										|ru = 'В наличии';
										|en = 'In stock'; fa = 'موجود در انبار';
										|it = 'In disposizione';
										|pl = 'Dostępny towar';
										|tr = 'Stokta'");
	
	SearchValue = New DataCompositionParameter("LineWithConfirmedQuality");
	DataParametersElement = SettingsComposer.Settings.DataParameters.FindParameterValue(SearchValue);
	DataParametersElement.Value = NStr("vi = 'Với chất lượng đã được xác nhận';
										|ru = 'С подтвержденным качеством';
										|en = 'With confirmed quality'; fa = 'با کیفیت تأییدشده';
										|it = 'With confirmed quality';
										|pl = 'With confirmed quality';
										|tr = 'Onaylanmış kaliteli'");
	
	SearchValue = New DataCompositionParameter("LineOnQualityControl");
	DataParametersElement = SettingsComposer.Settings.DataParameters.FindParameterValue(SearchValue);
	DataParametersElement.Value = NStr("vi = 'Đang trong quá trình kiểm soát chất lượng';
										|ru = 'На контроле качества';
										|en = 'Under quality control'; fa = 'تحت کنترل کیفیت';
										|it = 'Under quality control';
										|pl = 'Under quality control';
										|tr = 'Kalite kontrolde'");
	
	SearchValue = New DataCompositionParameter("StringCannotBeUnlocked");
	DataParametersElement = SettingsComposer.Settings.DataParameters.FindParameterValue(SearchValue);
	DataParametersElement.Value = NStr("vi = 'Không được phép mở khóa';
										|ru = 'Не подлежит разблокировке';
										|en = 'Not subject to unlocking'; fa = 'مشمول آزادسازی نیست';
										|it = 'Not subject to unlocking';
										|pl = 'Not subject to unlocking';
										|tr = 'Kilidi açılamaz'");
	
	SearchValue = New DataCompositionParameter("StringIsExpected");
	DataParametersElement = SettingsComposer.Settings.DataParameters.FindParameterValue(SearchValue);
	DataParametersElement.Value = NStr("vi = 'Đang chờ';
										|ru = 'Ожидается';
										|en = 'Expected'; fa = 'مورد انتظار';
										|it = 'Previsto';
										|pl = 'Oczekiwane';
										|tr = 'Beklenen'");
	
	SearchValue = New DataCompositionParameter("ExpectedStringCannotBeUnlocked");
	DataParametersElement = SettingsComposer.Settings.DataParameters.FindParameterValue(SearchValue);
	DataParametersElement.Value = NStr("vi = 'Đang chờ, không được phép mở khóa';
										|ru = 'Ожидается, не подлежит разблокировке';
										|en = 'Expected, not subject to unlocking'; fa = 'مورد انتظار، مشمول آزادسازی نیست';
										|it = 'Expected, not subject to unlocking';
										|pl = 'Expected, not subject to unlocking';
										|tr = 'Bekleniyor, kilidi açılamaz'");
	
	SearchValue = New DataCompositionParameter("RowTotal_");
	DataParametersElement = SettingsComposer.Settings.DataParameters.FindParameterValue(SearchValue);
	DataParametersElement.Value = NStr("vi = 'Tổng số';
										|ru = 'Всего';
										|en = 'Total'; fa = 'جمع کل';
										|it = 'In totale';
										|pl = 'Total';
										|tr = 'Toplam'");
	
	SetRequiredSettings(UserSettingsModified);
	
	// A call from self-service.
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		OutputSelectionParameter = SettingsComposer.Settings.OutputParameters.Items.Find("FilterOutput");
		If OutputSelectionParameter <> Undefined Then
			OutputSelectionParameter.Use = True;
			OutputSelectionParameter.Value = DataCompositionTextOutputType.DontOutput;
		EndIf;
	EndIf;

	// Standard layout of the report.
	ReportSettings = SettingsComposer.GetSettings();
	
	QueryText = DataCompositionSchema.DataSets.Main.Query;
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForInventoryAllocation();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Result = "SubstitutionCalculationOfReserves"; // @query-part-1
	
	ProvisionInDocumentsServer.InventoryAllocation(QueryText, TablesNames);
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextItemWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("Table.Products.UnitOfMeasure", "Table.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTheVolumeOfTheItem", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("Table.Products.UnitOfMeasure", "Table.Products"));
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	DataCompositionSchema.DataSets.Main.Query = QueryText;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
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
	Settings.Events.BeforeFillQuickSettingsBar	= True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If NewDCSettings = Undefined Then
		Return;
	EndIf;
	
	If SchemaKey = VariantKey Then
		Return;
	EndIf;
	
	NameOfDimensionToDisable = ?(GetFunctionalOption("UseGoodsQualityControl"),
		"QualityControlIsDisabled",
		"QualityControl_Enabled");
		
	SettingsStructure = NewDCSettings.Structure;
	For Each StructureItem In SettingsStructure Do
		If TypeOf(StructureItem) = Type("DataCompositionTable") Then
			
			For Each LayoutStringInfo In StructureItem.Rows Do
				If TypeOf(LayoutStringInfo) = Type("DataCompositionTableGroup") Then
					If LayoutStringInfo.Name = NameOfDimensionToDisable Then
						StructureItem.Rows.Delete(LayoutStringInfo);
					EndIf;
				EndIf;
			EndDo;
			For Each LayoutColumn In StructureItem.Columns Do
				If TypeOf(LayoutColumn) = Type("DataCompositionTableGroup") Then
					If LayoutColumn.Name = NameOfDimensionToDisable Then
						StructureItem.Columns.Delete(LayoutColumn);
					EndIf;
				EndIf;
			EndDo;
			
		ElsIf TypeOf(StructureItem) = Type("DataCompositionGroup") Then
			
			If StructureItem.Name = NameOfDimensionToDisable Then
				SettingsStructure.Items.Delete(StructureItem);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Is called before refilling the settings panel of the report form.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   FillParameters - Structure - Parameters to be loaded into the report.
//
Procedure BeforeFillQuickSettingsBar(Form, FillParameters) Export
	If Not GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		DataParameters = SettingsComposer.Settings.DataParameters;
		DataParameter = DataParameters.FindParameterValue(New DataCompositionParameter("ShowSeparateProducts"));
		DataParameter.UserSettingID = "";
	EndIf;
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;

	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);

EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Parameters = Form.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		If Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then
			
			// A structure with fields from the report variationdetermined.Before adding Command reports.Teams of reports.
			CommandDetails = Parameters.CommandDetails; // Structure -
			AdditionalCommandParameters = CommandDetails.AdditionalParameters; // Structure -
			If AdditionalCommandParameters.CommandName = "RemainingGoodsAndAvailability" Then
				Form.ParametersForm.Filter.Insert("Products", Parameters.CommandParameter);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
EndProcedure

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
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf