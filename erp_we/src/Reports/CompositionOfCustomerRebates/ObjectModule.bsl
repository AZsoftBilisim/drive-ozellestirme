//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// When composing the result.
// 
// Parameters:
//  ResultDocument - SpreadsheetDocument - Result document
//  DetailsData - DataCompositionDetailsData - decryption data
//  StandardProcessing - Boolean - Standard treatment
//
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	ReportSettings = SettingsComposer.GetSettings();
	TemplateComposer = New DataCompositionTemplateComposer;
	
	URBDocument = DataCompositionClientServer.GetParameter(ReportSettings, "URBDocument").Value;  // DocumentRef.ConditionsOfCustomerRebates
	ReportVariant = DataCompositionClientServer.GetParameter(ReportSettings, "ReportVariant").Value;  // String 
	DisplayArticle = DataCompositionClientServer.GetParameter(ReportSettings, "DisplayArticle").Value;  // Boolean
	AccordingToDocument = (ReportVariant = 2);
	
	ParametersStructure = AdditionalParametersForURB(URBDocument, AccordingToDocument);
	ParametersStructure.DisplayArticle = DisplayArticle;
	DesignHeadlines(ReportSettings, ParametersStructure, AccordingToDocument);
	
	DataSets = InitializeExternalDataSet(ParametersStructure, AccordingToDocument);
	
	CommentSegmentsAreNotFixed = NStr("vi = 'Dữ liệu về thành phần chứng từ chưa được ghi nhận và có thể thay đổi theo quy tắc tạo thành phần phân khúc hoặc thuộc tính';
										|ru = 'Данные о составе документа не зафиксированы, могут быть изменены по правилам формирования состава сегментов или свойств';
										|en = 'Document is not recorded, it can be changed according to the segment or property generation rules'; fa = 'Document is not recorded, it can be changed according to the segment or property generation rules';
										|it = 'Document is not recorded, it can be changed according to the segment or property generation rules';
										|pl = 'Document is not recorded, it can be changed according to the segment or property generation rules';
										|tr = 'Belge içeriği verileri sabit değildir, segment veya özellik içeriği oluşturma kurallarına göre değişiklik gösterebilir'");
	DataCompositionClientServer.SetParameter(
		ReportSettings,
		"CommentSegmentsAreNotFixed",
		CommentSegmentsAreNotFixed);
	
	CommentSegmentsAreFixed = NStr("vi = 'Việc ghi nhận và tính thưởng lũy kế được thực hiện theo dữ liệu của thành phần chứng từ đã ghi nhận';
									|ru = 'Расчет и начисление ретро-бонуса осуществляется по данным зафиксированного состава документа';
									|en = 'Rebate is calculated and accrued according to the data of the recorded document'; fa = 'Rebate is calculated and accrued according to the data of the recorded document';
									|it = 'Rebate is calculated and accrued according to the data of the recorded document';
									|pl = 'Rebate is calculated and accrued according to the data of the recorded document';
									|tr = 'Retro bonusu, sabitlenen belge içeriği verilerine göre hesaplanır ve tahakkuk ettirilir'");
	DataCompositionClientServer.SetParameter(
		ReportSettings,
		"CommentSegmentsAreFixed",
		CommentSegmentsAreFixed);
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, DataSets, DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, CompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm, Undefined - report form or report settings form.
//       Undefined when a call is without context.
//   VariantKey - String, Undefined - the name of the predefined
//       or unique identifier of the custom version of the report.
//       Undefined when a call is without context.
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.GenerateImmediately = True;
	Settings.EditOptionsAllowed = False;
	Settings.EditStructureAllowed = False;
	
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - Report form:
//      * Report - ReportObject.CalculateCustomerRebates
//      * Parameters - Structure:
//         ** CommandParameter - DocumentRef.ConditionsOfCustomerRebates
//   Cancel - Boolean - Indicates that the form was not created.
//       See the description of the parameter of the same name "Formaclientapplications.Joining the server" in the syntax assistant.
//   StandardProcessing - Boolean - Indicates that the standard (system) event processing has been performed.
//       See the description of the parameter of the same name "Formaclientapplications.Access to the server" in the syntax assistant.
//
// See also:
//   Procedure for displaying the added Commands in the form: Server Report.Call the() command.
//   Global handler for this event: reportdetermined.Access to the Server().
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Parameters = Form.Parameters;
	ReportSettings = SettingsComposer.GetSettings(); 
	
	AccordingToDocument = False;
	If ReportSettings.AdditionalProperties.VariantKey = "CompositionOfRebatesOfCustomersAccordingToDocumentContext" Then
		
		AccordingToDocument = True;
		
	EndIf;
	
	If Parameters.Property("CommandParameter") Then
		
		CommandParameter = Parameters.CommandParameter; // DocumentRef.ConditionsOfCustomerRebates
		CommandParameterType = TypeOf(CommandParameter);
		
		Form.ReportSettings.OptionSelectionAllowed = False;
		
		If CommandParameterType = Type("DocumentRef.ConditionsOfCustomerRebates") Then
			
			ParametersStructure = AdditionalParametersForURB(CommandParameter, AccordingToDocument);
			PartyList = ParametersStructure.PartyList;
			ContentOfGoods = ParametersStructure.ContentOfGoods;
			CompositionSegmentsByPartner = (PartyList = Enums.RebatesParticipants.PartnersSegments);
			CompositionSegmentsItemProperties = (ContentOfGoods = Enums.RebatesItems.ProductSegments
				Or ContentOfGoods = Enums.RebatesItems.ProductItemProperty);
			URBAgreed = ParametersStructure.URBAgreed;
			
			If Not URBAgreed
			   And Not AccordingToDocument Then
				
				MessageText = NStr("vi = 'Chỉ có thể lập báo cáo đối với các chứng từ đã thống nhất';
									|ru = 'Формирование отчета предусмотрено только для согласованных документов';
									|en = 'The report can be generated only for approved documents'; fa = 'The report can be generated only for approved documents';
									|it = 'The report can be generated only for approved documents';
									|pl = 'The report can be generated only for approved documents';
									|tr = 'Rapor oluşturma sadece onaylanan belgeler için sağlanır'");
				Raise MessageText;
					
			ElsIf Not CompositionSegmentsByPartner
			   And Not CompositionSegmentsItemProperties Then
				
				MessageText = NStr("vi = 'Chỉ có thể lập báo cáo đối với các chứng từ có tùy chỉnh theo phân khúc khách hàng/mặt hàng hoặc theo thuộc tính mặt hàng';
									|ru = 'Формирование отчета предусмотрено только для документов с настройкой по сегментам клиентов/номенклатуры или по свойству номенклатуры';
									|en = 'The report can be generated only for documents with customization by item/customer segments or by item property'; fa = 'The report can be generated only for documents with customization by item/customer segments or by item property';
									|it = 'The report can be generated only for documents with customization by item/customer segments or by item property';
									|pl = 'The report can be generated only for documents with customization by item/customer segments or by item property';
									|tr = 'Rapor oluşturma sadece müşteri/öğe segmentlerine veya öğe özelliğine göre ayarlanmış belgeler için sağlanır'");
				Raise MessageText;
				
			EndIf;
			
			FormDetailsToAdd = New Array(); // Array of FormAttribute
			
			StringType = New TypeDescription("EnumRef.RebatesItems");
			AttributeName = "ContentOfGoods";
			
			NewAttribute = New FormAttribute(AttributeName, StringType);
			FormDetailsToAdd.Add(NewAttribute);
			
			Form.ChangeAttributes(FormDetailsToAdd);
			
			CommonClientServer.SetFormAttributeByPath(
				Form, AttributeName, ContentOfGoods);
			
		EndIf;
		
	ElsIf Not ValueIsFilled(Parameters.VariantPresentation) Then
		
		Cancel = True;
		DocumentSynonym = Metadata.Documents.ConditionsOfCustomerRebates.Synonym;
		ErrorTemplate = NStr("vi = 'Báo cáo được sử dụng chỉ để mở từ chứng từ ""%1"".';
							|ru = 'Отчет предназначен только для открытия из документа ""%1"".';
							|en = 'You can only open the report from the ""%1"" document.'; fa = 'You can only open the report from the ""%1"" document.';
							|it = 'Отчет предназначен только для открытия из документа ""%1"".';
							|pl = 'You can only open the report from the ""%1"" document.';
							|tr = 'Raporun yalnızca ""%1"" belgesinde açılması amaçlandı.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, DocumentSynonym);
		Raise ErrorText;
		
	EndIf;

EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//   For example, if the report schema depends on the option key or report parameters.
//   For schema changes to take effect, call the ReportServer method.Connect the circuit().
//
// Parameters:
//   Context - See CommonForm.ReportForm
//   SchemaKey - String -
//       ID of the current configuration Composer schema.
//       By default, it is not filled in (this means that the Composer is initialized based on the main schema).
//       It is used for optimization in order to reinitialize the Composer as rarely as possible).
//       It may not be used if reinitialization is performed unconditionally.
//   VariantKey - String, Undefined -
//       The name of a predefined or unique identifier of a custom version of the report.
//       It is undefined when the call is for a decryption option or without context.
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Composer after it is initialized.
//       It is uncertain when the option settings do not need to be loaded (already loaded earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the settings Composer after it is initialized.
//       Undefined when user settings do not need to be loaded (already loaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If SchemaKey = VariantKey Then
		Return;
	EndIf;
	
	If NewDCSettings = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		
		Parameters = Context.Parameters;
		If Parameters.Property("CommandParameter") Then
			
			CommandParameter = Parameters.CommandParameter; // DocumentRef.ConditionsOfCustomerRebates
			FillInParametersByContext(CommandParameter, NewDCSettings);
			
			If CommonClientServer.HasAttributeOrObjectProperty(Context, "ContentOfGoods") Then
				
				ContentOfGoods = Context.ContentOfGoods;
				
				If ContentOfGoods <> Enums.RebatesItems.ProductSegments
				   And ContentOfGoods <> Enums.RebatesItems.ProductItemProperty Then
					
					DisplayArticle = DataCompositionSchema.Parameters.DisplayArticle;
					DisplayArticle.UseRestriction = True;
					ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	SchemaKey = VariantKey;
	
EndProcedure

#EndRegion

#Region Private

Procedure DesignHeadlines(ReportSettings, ParametersStructure, AccordingToDocument)
	
	PartyList = ParametersStructure.PartyList;
	ContentOfGoods = ParametersStructure.ContentOfGoods;
	Attendees = ParametersStructure.Attendees;
	Goods = ParametersStructure.Goods;
	SegmentsAreRecorded = ParametersStructure.RecordingIsCompleted;
	DisplayArticle = ParametersStructure.DisplayArticle;
	
	If AccordingToDocument Then
		PresentationOfDocument = ParametersStructure.URBDocumentPresentation;
	Else
		PresentationOfDocument = ParametersStructure.URBPrimaryDocumentPresentation;
	EndIf;
		
	TitleTemplate1 = NStr("vi = 'Thành phần chứng từ %1';
							|ru = 'Состав документа %1';
							|en = '%1 document content'; fa = '%1 document content';
							|it = '%1 document content';
							|pl = '%1 document content';
							|tr = '%1 belgesinin içeriği'");
	ReportHeader = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, PresentationOfDocument);
	DataCompositionClientServer.SetOutputParameter(ReportSettings, "Title", ReportHeader);
	
	For Each StructureItem In ReportSettings.Structure Do
		
		If StructureItem.Name = "Goods" Then
			
			If ContentOfGoods = Enums.RebatesItems.ProductSegments
			  Or ContentOfGoods = Enums.RebatesItems.ProductItemProperty Then
				
				If Goods = Enums.RebatesLists.Selected_ Then
					
					GroupHeader = NStr("vi = 'Hàng hóa được chọn';
										|ru = 'Выбранные товары';
										|en = 'Selected goods'; fa = 'کالای انتخاب‌شده';
										|it = 'Выбранные товары';
										|pl = 'Wybrane towary';
										|tr = 'Seçili ürünler'");
					
				Else
					
					GroupHeader = NStr("vi = 'Tất cả, ngoại trừ các mặt hàng được chọn';
										|ru = 'Все, кроме выбранных товаров';
										|en = 'All except for selected goods'; fa = 'All except for selected goods';
										|it = 'All except for selected goods';
										|pl = 'All except for selected goods';
										|tr = 'Seçilen ürünler hariç tümü'");
					
				EndIf;
				DataCompositionClientServer.SetOutputParameter(StructureItem, "Title", GroupHeader);
				
				LayoutField = New DataCompositionField("SKU");
				
				For Each GroupingField In StructureItem.GroupFields.Items Do
				
					If TypeOf(GroupingField) = Type("DataCompositionGroupField")
					   And GroupingField.Field = LayoutField Then
					
						GroupingField.Use = DisplayArticle;
						Break;
						
					EndIf;
					
				EndDo;
				
				LayoutField = New DataCompositionField("Characteristic");
				
				For Each GroupingField In StructureItem.GroupFields.Items Do
				
					If TypeOf(GroupingField) = Type("DataCompositionGroupField")
					   And GroupingField.Field = LayoutField Then
					
						GroupingField.Use =
							(ContentOfGoods = Enums.RebatesItems.ProductSegments);
						Break;
						
					EndIf;
					
				EndDo;
				
			Else
				
				StructureItem.Use = False;
				
			EndIf;
			
		ElsIf StructureItem.Name = "Partners" Then
			
			If PartyList = Enums.RebatesParticipants.PartnersSegments Then
				
				If Attendees = Enums.RebatesLists.Selected_ Then
					
					GroupHeader = NStr("vi = 'Khách hàng được chọn';
										|ru = 'Выбранные клиенты';
										|en = 'Selected customers'; fa = 'Selected customers';
										|it = 'Выбранные клиенты';
										|pl = 'Selected customers';
										|tr = 'Seçili müşteriler'");
					
				Else
					
					GroupHeader = NStr("vi = 'Tất cả, ngoại trừ các khách hàng được chọn';
										|ru = 'Все, кроме выбранных клиентов';
										|en = 'All except for selected customers'; fa = 'All except for selected customers';
										|it = 'All except for selected customers';
										|pl = 'All except for selected customers';
										|tr = 'Seçilen müşteriler hariç tümü'");
					
				EndIf;
				DataCompositionClientServer.SetOutputParameter(StructureItem, "Title", GroupHeader);
				
			Else
				
				StructureItem.Use = False;
				
			EndIf;
			
		ElsIf StructureItem.Name = "CommentSegmentsAreNotFixed" Then
			
			ToUseGrouping = (Not SegmentsAreRecorded And Not AccordingToDocument);
			StructureItem.Use = ToUseGrouping; 
			
		ElsIf StructureItem.Name = "CommentSegmentsAreFixed" Then
			
			ToUseGrouping = (SegmentsAreRecorded And Not AccordingToDocument);
			StructureItem.Use = ToUseGrouping;
			
		ElsIf StructureItem.Name = "CommentIsEmpty" Then
			
			StructureItem.Use = True;
			
		EndIf;
		
	EndDo;

EndProcedure

// Fills in parameters from the passed context.
// 
// Parameters:
//  CommandParameter - AnyRef
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Composer after it is initialized.
//       It is uncertain when the option settings do not need to be loaded (already loaded earlier).
//
Procedure FillInParametersByContext(CommandParameter, NewDCSettings)
	
	CommandParameterType = TypeOf(CommandParameter);
	
	If CommandParameterType = Type("DocumentRef.ConditionsOfCustomerRebates") Then
		
		DataCompositionClientServer.SetParameter(NewDCSettings, "URBDocument", CommandParameter);
		
	EndIf;
	
EndProcedure

Function InitializeExternalDataSet(ParametersStructure, AccordingToDocument)
	
	DataSet = New Structure;
	DataSet.Insert("GoodsDataset", New ValueTable);
	DataSet.Insert("DataSetPartners", New ValueTable);
	
	URBDocument = ParametersStructure.URBDocument;
	URBPrimaryDocument = ParametersStructure.URBPrimaryDocument;
	PartyList = ParametersStructure.PartyList;
	ContentOfGoods = ParametersStructure.ContentOfGoods;
	SegmentsAreRecorded = ParametersStructure.RecordingIsCompleted;
	
	CompositionSegmentsByPartner = (PartyList = Enums.RebatesParticipants.PartnersSegments);
	CompositionItemSegments = (ContentOfGoods = Enums.RebatesItems.ProductSegments);
	CompositionPropertyOfItem = (ContentOfGoods = Enums.RebatesItems.ProductItemProperty); 
	
	If CompositionSegmentsByPartner
	 Or CompositionItemSegments
	 Or CompositionPropertyOfItem Then
	
		If SegmentsAreRecorded
		   And Not AccordingToDocument Then
			
			Query = New Query;
			Query.SetParameter("TermDocument", URBPrimaryDocument);
			Query.SetParameter("CompositionSegmentsByPartner", CompositionSegmentsByPartner);
			Query.SetParameter("CompositionItemSegments",
				Max(CompositionItemSegments, CompositionPropertyOfItem));
			
			Query.Text =
			"SELECT
			|	CustomerRebatesItems.Products AS Products,
			|	CustomerRebatesItems.Characteristic AS Characteristic
			|FROM
			|	InformationRegister.CustomerRebatesItems AS CustomerRebatesItems
			|WHERE
			|	CustomerRebatesItems.TermDocument = &TermDocument
			|	AND &CompositionItemSegments
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CustomerRebatesCounterparties.Partner AS Partner
			|FROM
			|	InformationRegister.CustomerRebatesCounterparties AS CustomerRebatesCounterparties
			|WHERE
			|	CustomerRebatesCounterparties.TermDocument = &TermDocument
			|	AND &CompositionSegmentsByPartner"; 
			
			Result = Query.ExecuteBatch();
			DataSet.GoodsDataset = Result[0].Unload();
			DataSet.DataSetPartners = Result[1].Unload();
			
		Else 
			
			If AccordingToDocument Then
				
				If CompositionPropertyOfItem Then
					
					DataSet.GoodsDataset = ItemsByProperty(ParametersStructure, AccordingToDocument);
					
				Else
					
					DataSet.GoodsDataset = RebatesServer.FillInDataForFixingGoodsSegments(
						URBDocument, 
						AccordingToDocument);
						
				EndIf;
					
				DataSet.DataSetPartners = RebatesServer.FillInDataForFixingPartnerSegments(
					URBDocument, 
					AccordingToDocument);
				
			Else
				
				If CompositionPropertyOfItem Then
					
					DataSet.GoodsDataset = ItemsByProperty(ParametersStructure, AccordingToDocument);
					
				Else
					
					DataSet.GoodsDataset = RebatesServer.FillInDataForFixingGoodsSegments(URBPrimaryDocument);
					
				EndIf;
				
				DataSet.DataSetPartners = RebatesServer.FillInDataForFixingPartnerSegments(URBPrimaryDocument);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return DataSet;
	
EndFunction

Function ItemsByProperty(ParametersStructure, AccordingToDocument)
	
	TableOfGoods = New ValueTable;
	TableOfGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfGoods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	CheckResult = RebatesServer.ItemPropertyVerificationData(ParametersStructure.ProductItemProperty);
	
	If CheckResult.AllowedToUse Then
		
		TextItemsByProperty = RebatesServer.QueryTextItemsByProperty(
			True,
			ParametersStructure.ProductItemProperty,
			CheckResult.Property,
			AccordingToDocument);
		
		TextCompositionOfItems =
		"SELECT
		|	ItemsByProperty.TermDocument AS TermDocument,
		|	ItemsByProperty.Characteristic AS Characteristic,
		|	ItemsByProperty.Products AS Products
		|FROM
		|	TT_ItemsByProperty AS ItemsByProperty
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON ItemsByProperty.Products = CatalogProducts.Ref
		|			AND CatalogProducts.ItemsType IN (&ItemsTypes)
		|AUTOORDER";
		
		TextSeparator_ = Common.QueryBatchSeparator();
		
		FragmentsOfTheQuery = New Array; // Array of String
		FragmentsOfTheQuery.Add(TextItemsByProperty);
		FragmentsOfTheQuery.Add(TextCompositionOfItems);
		
		QueryText = StrConcat(FragmentsOfTheQuery, TextSeparator_);
		
		Query = New Query;
		Query.Text = QueryText;
		If AccordingToDocument Then
			Query.SetParameter("SourceDocument_", ParametersStructure.URBDocument);
		Else
			Query.SetParameter("SourceDocument_", ParametersStructure.URBPrimaryDocument);
		EndIf;
		Query.SetParameter("ProductItemProperty", CheckResult.Property);
		ItemsTypes = RebatesServer.SupportedItemTypes();
		Query.SetParameter("ItemsTypes", ItemsTypes);
		
		TableOfGoods = Query.Execute().Unload();
		
	EndIf;
		
	Return TableOfGoods;
	
EndFunction

Function AdditionalParametersForURB(URBDocument, AccordingToDocument = False)
	
	ParametersStructure = ReportParametersStructure();
	
	Query = New Query;
	Query.SetParameter("TermDocument", URBDocument);
	Query.SetParameter("AccordingToDocument", AccordingToDocument);
	
	If AccordingToDocument Then
		
		QueryText =
		"SELECT
		|	ConditionData.FilterParties AS Attendees,
		|	ConditionData.FilterOfProducts_ AS Goods,
		|	ISNULL(CustomerRebatesKinds.PartyList, VALUE(Enum.RebatesParticipants.EmptyRef)) AS PartyList,
		|	ISNULL(CustomerRebatesKinds.ContentOfGoods, VALUE(Enum.RebatesItems.EmptyRef)) AS ContentOfGoods,
		|	FALSE AS RecordingIsCompleted,
		|	ConditionData.Status = VALUE(Enum.RebatesDocumentStatuses.Approved) AS URBAgreed,
		|	CASE
		|		WHEN ConditionData.Patch
		|			THEN ConditionData.CorrectedDocument
		|		ELSE ConditionData.Ref
		|	END AS URBPrimaryDocument,
		|	ConditionData.Presentation AS URBDocumentPresentation,
		|	CASE
		|		WHEN ConditionData.Patch
		|			THEN ConditionData.CorrectedDocument.Presentation
		|		ELSE ConditionData.Presentation
		|	END AS URBPrimaryDocumentPresentation,
		|	ISNULL(CustomerRebatesKinds.ProductItemProperty, """") AS ProductItemProperty
		|FROM
		|	Document.ConditionsOfCustomerRebates AS ConditionData
		|		LEFT JOIN Catalog.CustomerRebatesKinds AS CustomerRebatesKinds
		|		ON ConditionData.RebateKind = CustomerRebatesKinds.Ref
		|WHERE
		|	ConditionData.Ref = &TermDocument";
		
	Else
		
		QueryText =
		"SELECT ALLOWED
		|	ISNULL(CustomerRebatesConditions.Attendees, VALUE(Enum.RebatesLists.EmptyRef)) AS Attendees,
		|	ISNULL(CustomerRebatesConditions.Goods, VALUE(Enum.RebatesLists.EmptyRef)) AS Goods,
		|	ISNULL(CustomerRebatesConditions.PartyList, VALUE(Enum.RebatesParticipants.EmptyRef)) AS PartyList,
		|	ISNULL(CustomerRebatesConditions.ContentOfGoods, VALUE(Enum.RebatesItems.EmptyRef)) AS ContentOfGoods,
		|	ISNULL(CustomerRebatesConditions.RecordingIsCompleted, FALSE) AS RecordingIsCompleted,
		|	ISNULL(CustomerRebatesConditions.TermDocument, FALSE) <> FALSE AS URBAgreed,
		|	ISNULL(CustomerRebatesConditions.TermDocument, VALUE(Document.ConditionsOfCustomerRebates.EmptyRef)) AS URBPrimaryDocument,
		|	ConditionData.Presentation AS URBDocumentPresentation,
		|	CASE
		|		WHEN NOT CustomerRebatesConditions.TermDocument IS NULL
		|			THEN CustomerRebatesConditions.TermDocument.Presentation
		|		ELSE """"
		|	END AS URBPrimaryDocumentPresentation,
		|	ISNULL(CustomerRebatesKinds.ProductItemProperty, """") AS ProductItemProperty
		|FROM
		|	Document.ConditionsOfCustomerRebates AS ConditionData
		|		LEFT JOIN InformationRegister.CustomerRebatesConditions AS CustomerRebatesConditions
		|		ON ConditionData.CorrectedDocument = CustomerRebatesConditions.TermDocument
		|			AND (ConditionData.Patch)
		|		INNER JOIN Catalog.CustomerRebatesKinds AS CustomerRebatesKinds
		|		ON (CustomerRebatesConditions.Kind = CustomerRebatesKinds.Ref)
		|WHERE
		|	ConditionData.Ref = &TermDocument
		|	AND NOT CustomerRebatesConditions.TermDocument IS NULL
		|
		|UNION ALL
		|
		|SELECT
		|	ISNULL(CustomerRebatesConditions.Attendees, VALUE(Enum.RebatesLists.EmptyRef)),
		|	ISNULL(CustomerRebatesConditions.Goods, VALUE(Enum.RebatesLists.EmptyRef)),
		|	ISNULL(CustomerRebatesConditions.PartyList, VALUE(Enum.RebatesParticipants.EmptyRef)),
		|	ISNULL(CustomerRebatesConditions.ContentOfGoods, VALUE(Enum.RebatesItems.EmptyRef)),
		|	ISNULL(CustomerRebatesConditions.RecordingIsCompleted, FALSE),
		|	ISNULL(CustomerRebatesConditions.TermDocument, FALSE) <> FALSE,
		|	ISNULL(CustomerRebatesConditions.TermDocument, VALUE(Document.ConditionsOfCustomerRebates.EmptyRef)),
		|	ConditionData.Presentation,
		|	CASE
		|		WHEN NOT CustomerRebatesConditions.TermDocument IS NULL
		|			THEN CustomerRebatesConditions.TermDocument.Presentation
		|		ELSE """"
		|	END,
		|	ISNULL(CustomerRebatesKinds.ProductItemProperty, """")
		|FROM
		|	Document.ConditionsOfCustomerRebates AS ConditionData
		|		LEFT JOIN InformationRegister.CustomerRebatesConditions AS CustomerRebatesConditions
		|		ON ConditionData.Ref = CustomerRebatesConditions.TermDocument
		|			AND (NOT ConditionData.Patch)
		|		LEFT JOIN Catalog.CustomerRebatesKinds AS CustomerRebatesKinds
		|		ON (CustomerRebatesConditions.Kind = CustomerRebatesKinds.Ref)
		|WHERE
		|	ConditionData.Ref = &TermDocument
		|	AND NOT CustomerRebatesConditions.TermDocument IS NULL";
		
	EndIf;
	
	Query.Text = QueryText;
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		Selection.Next();
		FillPropertyValues(ParametersStructure, Selection);
		
	EndIf;
	
	ParametersStructure.URBDocument = URBDocument;
	
	Return ParametersStructure;
	
EndFunction

Function ReportParametersStructure()
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("URBDocument", Documents.ConditionsOfCustomerRebates.EmptyRef());
	ParametersStructure.Insert("URBPrimaryDocument", Documents.ConditionsOfCustomerRebates.EmptyRef());
	ParametersStructure.Insert("URBDocumentPresentation", "");
	ParametersStructure.Insert("URBPrimaryDocumentPresentation", "");
	ParametersStructure.Insert("PartyList", Enums.RebatesParticipants.EmptyRef());
	ParametersStructure.Insert("ContentOfGoods", Enums.RebatesItems.EmptyRef());
	ParametersStructure.Insert("Attendees", Enums.RebatesLists.EmptyRef());
	ParametersStructure.Insert("Goods", Enums.RebatesLists.EmptyRef());
	ParametersStructure.Insert("RecordingIsCompleted", False);
	ParametersStructure.Insert("URBAgreed", False);
	ParametersStructure.Insert("DisplayArticle", False);
	ParametersStructure.Insert("ProductItemProperty", "");
	
	Return ParametersStructure;
	
EndFunction

#EndRegion

#EndIf