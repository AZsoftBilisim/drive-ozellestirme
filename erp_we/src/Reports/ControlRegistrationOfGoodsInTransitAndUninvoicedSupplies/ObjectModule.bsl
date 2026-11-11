#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

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
	Settings.Events.BeforeImportSettingsToComposer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	ReportSettings = ThisForm.ReportSettings;
	
	Schema = GetFromTempStorage(ThisForm.ReportSettings.SchemaURL);
	
	AvailableValues = AvailableTypesOfOperationsAndQueries();
	If AvailableValues.Count() = 2 Then
		Parameters.VariantKey =  "ControlRegistrationOfGoodsInTransitAndUninvoicedSupplies";
	ElsIf AvailableValues.Count() = 1 Then
		If AvailableValues[0].OperationKind = "GoodsInTransit" Then
			Parameters.VariantKey =  "ControlRegistrationOfGoodsInTransit";
		ElsIf AvailableValues[0].OperationKind = "UninvoicedDelivery" Then
			Parameters.VariantKey =  "ControlRegistrationOfUninvoicedSupplies";
		EndIf;
	EndIf;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//   For example, if the report schema depends on the option key or report parameters.
//   For schema changes to take effect, call the ReportServer method.Connect the circuit().
//
// Parameters:
//   Context - Arbitrary - 
//       Parameters of the context in which the report is used.
//       Used for passing the ReportServer method parameters.Connect the circuit().
//   SchemaKey - String -
//       ID of the current configuration Builder schema.
//       By default, it is empty (this means that the linker is initialized based on the main schema).
//       Used for optimization to reinitialize the linker as rarely as possible).
//       It may not be used if reinitialization is performed unconditionally.
//   VariantKey - String, Undefined -
//       Name of the predefined or unique ID of the custom version of the report.
//       Undefined when calling for a decryption option or without context.
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Builder after it is initialized.
//       Undefined when the option settings do not need to be loaded (already loaded earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the Settings Composer after it is initialized.
//       It is uncertain when user settings do not need to be loaded (already loaded earlier).
//
// Examples:
// 1. The Composer of the report is initialized based on the scheme from the general Templates:
//	If the key of the scheme <> is "1" Then
//		Schema Key = "1";
//		SCHEMACD = Get a Public package("My Public Schemacompositions");
//		Server report.Connect a schema(This is an Object, Context, Schema, Schema Key);
//	The end if;
//
// 2. The scheme depends on the value of the parameter displayed in the user settings of the report:
//	If the type of ID is(New usersenastroykid) = Type("Custom setups of Data components") Then
//		Full Data objectName = "";
//		For Each Cd element From The New Userenastroykid.Elements of the Cycle
//			If the type of ID is (CD element) = Type("Parameter setter values") Then
//				Parameter Name = String(element).Parameter);
//				If Parameter Name = "Data objectmethod" Then
//					Full Data objectName = Data element.Value;
//				The end if;
//			The end if;
//		The end of the cycle;
//		If the Schema key <> is the full Data objectName, then
//			Schema Key = Full Data objectname;
//			Schemacd = New schemacomposedata;
//			Filling in the schema...
//			Server report.Connect a schema(This is an Object, Context, Schema, Schema Key);
//		The end if;
//	The end if;
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	// Localization of the list of values
	AvailableValues = AvailableValuesForOperationTypeField();
	
	OperationKind = DataCompositionSchema.DataSets.DataSet.Fields.Find("OperationKind");
	OperationKind.SetAvailableValues(AvailableValues);
		
	ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	DataCompositionSchema.DataSets.DataSet.Query = QueryText();
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)
	PeriodParameter_ = DataCompositionClientServer.GetParameter(SettingsComposer, "Period");
	DataCompositionClientServer.SetParameter(SettingsComposer, "PeriodLimit", New Boundary(EndOfDay(PeriodParameter_.Value), BoundaryType.Including));
	
	TypesOfOperationsAndSynonyms = TypesOfOperationsAndSynonyms();
	
	// String literals
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterReceiptOfGoods", NStr("vi = 'Hãy lập chứng từ tiếp nhận hàng hóa';
																												|ru = 'Оформите поступление товаров';
																												|en = 'Register goods receipt'; fa = 'ثبت دریافت کالا';
																												|it = 'Formalizza l''arrivo della merce';
																												|pl = 'Sporządź wpływ towarów';
																												|tr = 'İrsaliye düzenle'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterPurchaseOfGoodsAndServices", NStr("vi = 'Hãy lập chứng từ mua hàng hóa và dịch vụ';
																															|ru = 'Оформите приобретение товаров и услуг';
																															|en = 'Register vendor invoice'; fa = 'ثبت فاکتور فروشنده';
																															|it = 'Formalizza l''acquisizione delle merci e dei servizi';
																															|pl = 'Sporządź nabycie towarów i usług';
																															|tr = 'Satın alma faturası düzenleyin'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationRegisterCustomsImportDeclaration", NStr("vi = 'Điền vào tờ khai nhập khẩu hải quan';
																															|ru = 'Оформите таможенную декларацию на импорт';
																															|en = 'Fill in customs import declaration'; fa = 'تکمیل اظهارنامه واردات گمرکی';
																															|it = 'Formalizza la dichiarazione doganale per l''importazione';
																															|pl = 'Sporządź deklarację celną na import';
																															|tr = 'Gümrük ithalat beyannamesi düzenleyin'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineRecommendationIssueNotificationOfImportOfTraceableGoods", NStr("vi = 'Hãy tạo thông báo nhập hàng hóa có nguồn gốc xuất xứ';
																																	|ru = 'Оформите уведомление о ввозе ПТ';
																																	|en = 'Register notification of traceable goods import'; fa = 'Register notification of traceable goods import';
																																	|it = 'Compilare la dichiarazione di importazione di lotti di merci';
																																	|pl = 'Utwórz powiadomienie o wwozie PT';
																																	|tr = 'PT için bir ithalat bildirimi yayınlayın'"));
		
	DataCompositionClientServer.SetParameter(SettingsComposer, "GoodsInTransit", TypesOfOperationsAndSynonyms["GoodsInTransit"]);
	DataCompositionClientServer.SetParameter(SettingsComposer, "UninvoicedDelivery", TypesOfOperationsAndSynonyms["UninvoicedDelivery"]);
	
EndProcedure

Function AvailableTypesOfOperationsAndQueries()
	
	Available2 = New ValueTable;
	Available2.Columns.Add("OperationKind", Common.StringTypeDetails(200));
	Available2.Columns.Add("TypeOfOperationSynonym", Common.StringTypeDetails(200));
	Available2.Columns.Add("NameOfRequestText", Common.StringTypeDetails(200));
	
	TypesOfOperationsAndSynonyms = TypesOfOperationsAndSynonyms();
	
	// Disabled by a combination of functional options
	If GetFunctionalOption("UseGoodsInTransitFromVendors") Then
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "GoodsInTransit", "QueryTextGoodsInTransit");
	EndIf;
	If GetFunctionalOption("UseUninvoicedDeliveries") Then
		AddOperationTypeAndRequest(Available2, TypesOfOperationsAndSynonyms, "UninvoicedDelivery", "QueryTextUninvoicedDelivery");
	EndIf;
	
	Return Available2;
	
EndFunction

Procedure ConnectRequest(DynamicQueryText, ConnectingRequest, NumberOfConnectedRequests,
	TemporaryTableQueryText = Undefined)
	
	TemporaryTableQueryText = ?(ValueIsFilled(TemporaryTableQueryText),
		TemporaryTableQueryText + Common.QueryBatchSeparator(), "");
	
	If NumberOfConnectedRequests = 0 Then
		DynamicQueryText = DynamicQueryText + TemporaryTableQueryText + ConnectingRequest;
	Else
		DynamicQueryText = DynamicQueryText + Chars.LF + Chars.LF 
			+ "UNION ALL" + Chars.LF + Chars.LF;
			
		StringOfLayoutFields = "{SELECT
			|	Products.*,
			|	Characteristic.*,
			|	Series.*,
			|	Purpose.*}";

		EnablingRequestPreparation = StrReplace(ConnectingRequest, "ALLOWED", "");
		EnablingRequestPreparation = StrReplace(EnablingRequestPreparation, StringOfLayoutFields, "");
		
		DynamicQueryText = TemporaryTableQueryText + DynamicQueryText + EnablingRequestPreparation;
	EndIf;
		
	NumberOfConnectedRequests = NumberOfConnectedRequests + 1;
EndProcedure

Function TemporaryTableQueryText(DisplayGoodsEnRoute, WithdrawUnfacturedDeliveries)
	
	QueryText = 
	"SELECT ALLOWED
	|	ItemsLocationAttributes.Ref,
	|	ItemsLocationAttributes.Products,
	|	ItemsLocationAttributes.Characteristic,
	|	ItemsLocationAttributes.Series,
	|	ItemsLocationAttributes.Purpose,
	|	ItemsLocationAttributes.Contract AS Contract,
	|	ItemsLocationAttributes.Partner AS Partner,
	|	ItemsLocationAttributes.Counterparty AS Counterparty
	|INTO DimensionKeys
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS ItemsLocationAttributes
	|WHERE
	|	ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|	AND (&PurchaseRegistrationOptions)
	|	AND NOT ItemsLocationAttributes.DeletionMark
	|
	|INDEX BY
	|	ItemsLocationAttributes.Ref";
	
	Conditions = New Array();
	If DisplayGoodsEnRoute Then
		Conditions.Add("ItemsLocationAttributes.Contract.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.GoodsInTransit)");
	EndIf;
	If WithdrawUnfacturedDeliveries Then
		Conditions.Add("ItemsLocationAttributes.Contract.PurchaseRegistrationOption IN (
		|	VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoods),
		|	VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices))");
	EndIf;
	ConditionsText = StrConcat(Conditions, " OR ");
	
	QueryText = StrReplace(QueryText, "&PurchaseRegistrationOptions", ConditionsText);
	
	Return QueryText;
	
EndFunction

Function QueryTextGoodsInTransit()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = 
	"SELECT
	|	&GoodsInTransit AS OperationKind,
	|	CASE
	|		WHEN ProductsFromPartnersAreLeftovers.CountBalance > 0
	|			THEN &LineRecommendationRegisterReceiptOfGoods
	|		WHEN ProductsFromPartnersAreLeftovers.CountBalance < 0
	|			THEN &LineRecommendationRegisterPurchaseOfGoodsAndServices
	|	END AS Recommendation,
	|	DimensionKeys.Products AS Products,
	|	DimensionKeys.Characteristic AS Characteristic,
	|	DimensionKeys.Series AS Series,
	|	DimensionKeys.Purpose AS Purpose,
	|	ProductsFromPartnersAreLeftovers.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DimensionKeys.Partner AS Partner,
	|	DimensionKeys.Counterparty AS Counterparty,
	|	ProductsFromPartnersAreLeftovers.CCDNumber AS CCDNumber,
	|	DimensionKeys.Contract AS Contract,
	|	ProductsFromPartnersAreLeftovers.CountBalance AS Count
	|{SELECT
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(
	|		&PeriodLimit, ItemsLocationAttributes IN (
	|		SELECT
	|			Keys.Ref
	|		FROM
	|			DimensionKeys AS Keys
	|		)) AS ProductsFromPartnersAreLeftovers
	|	LEFT JOIN DimensionKeys AS DimensionKeys
	|	ON DimensionKeys.Ref = ProductsFromPartnersAreLeftovers.ItemsLocationAttributes
	|WHERE
	|	ProductsFromPartnersAreLeftovers.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|
	|UNION ALL
	|
	|SELECT
	|	&GoodsInTransit AS OperationKind,
	|	CASE
	|		WHEN GoodsForRegistrationOfImportDocumentsBalance.CountBalance > 0
	|			THEN CASE 
	|					WHEN ImportDocumentType = &ImportDocumentType 
	|						THEN &LineRecommendationRegisterCustomsImportDeclaration
	|						ELSE &LineRecommendationIssueNotificationOfImportOfTraceableGoods 
	|					END	
	|		WHEN GoodsForRegistrationOfImportDocumentsBalance.CountBalance < 0
	|			THEN &LineRecommendationRegisterPurchaseOfGoodsAndServices
	|	END,
	|	GoodsForRegistrationOfImportDocumentsBalance.ItemsLocationAttributes.Products,
	|	GoodsForRegistrationOfImportDocumentsBalance.ItemsLocationAttributes.Characteristic,
	|	GoodsForRegistrationOfImportDocumentsBalance.ItemsLocationAttributes.Series,
	|	GoodsForRegistrationOfImportDocumentsBalance.ItemsLocationAttributes.Purpose,
	|	GoodsForRegistrationOfImportDocumentsBalance.InventoryOwnerAttribute,
	|	GoodsForRegistrationOfImportDocumentsBalance.Vendor,
	|	NULL,
	|	NULL,
	|	NULL,
	|	GoodsForRegistrationOfImportDocumentsBalance.CountBalance
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(
	|		&PeriodLimit, ) AS GoodsForRegistrationOfImportDocumentsBalance
	|WHERE
	|	GoodsForRegistrationOfImportDocumentsBalance.DocumentInflow.BusinessOperation IN
	|		(
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit)
	|		)";
	
	Return QueryText;
EndFunction

Function QueryTextUninvoicedDelivery()
	// String literals are localized in the report's SCD settings
	// Datasets - Fields - Available values.
	QueryText = 
	"SELECT
	|	&UninvoicedDelivery AS OperationKind,
	|	CASE
	|		WHEN ProductsFromPartnersAreLeftovers.CountBalance < 0
	|			THEN &LineRecommendationRegisterPurchaseOfGoodsAndServices
	|		WHEN ProductsFromPartnersAreLeftovers.CountBalance > 0
	|			THEN &LineRecommendationRegisterReceiptOfGoods
	|	END AS Recommendation,
	|	DimensionKeys.Products AS Products,
	|	DimensionKeys.Characteristic AS Characteristic,
	|	DimensionKeys.Series AS Series,
	|	DimensionKeys.Purpose AS Purpose,
	|	ProductsFromPartnersAreLeftovers.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DimensionKeys.Partner AS Partner,
	|	DimensionKeys.Counterparty AS Counterparty,
	|	ProductsFromPartnersAreLeftovers.CCDNumber AS CCDNumber,
	|	DimensionKeys.Contract AS Contract,
	|	ProductsFromPartnersAreLeftovers.CountBalance AS Count
	|{SELECT
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Purpose.*}
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(
	|		&PeriodLimit, ItemsLocationAttributes IN (
	|		SELECT
	|			Keys.Ref
	|		FROM
	|			DimensionKeys AS Keys
	|		)) AS ProductsFromPartnersAreLeftovers
	|	LEFT JOIN DimensionKeys AS DimensionKeys
	|	ON DimensionKeys.Ref = ProductsFromPartnersAreLeftovers.ItemsLocationAttributes
	|WHERE
	|	ProductsFromPartnersAreLeftovers.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|
	|UNION ALL
	|
	|SELECT
	|	&UninvoicedDelivery AS OperationKind,
	|	CASE
	|		WHEN GoodsForRegistrationOfImportDocumentsBalance.CountBalance > 0
	|			THEN  
	|					&LineRecommendationIssueNotificationOfImportOfTraceableGoods
	|	END,
	|	GoodsForRegistrationOfImportDocumentsBalance.ItemsLocationAttributes.Products,
	|	GoodsForRegistrationOfImportDocumentsBalance.ItemsLocationAttributes.Characteristic,
	|	GoodsForRegistrationOfImportDocumentsBalance.ItemsLocationAttributes.Series,
	|	GoodsForRegistrationOfImportDocumentsBalance.ItemsLocationAttributes.Purpose,
	|	GoodsForRegistrationOfImportDocumentsBalance.InventoryOwnerAttribute,
	|	GoodsForRegistrationOfImportDocumentsBalance.Vendor,
	|	NULL,
	|	NULL,
	|	NULL,
	|	GoodsForRegistrationOfImportDocumentsBalance.CountBalance
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(
	|		&PeriodLimit, ) AS GoodsForRegistrationOfImportDocumentsBalance
	|WHERE
	|	GoodsForRegistrationOfImportDocumentsBalance.DocumentInflow.BusinessOperation IN
	|		(
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery)
	|)
	|	AND GoodsForRegistrationOfImportDocumentsBalance.CountBalance > 0";
	
	Return QueryText;
EndFunction

Function AvailableValuesForOperationTypeField()
	
	AvailableTypesOfOperationsAndQueries = AvailableTypesOfOperationsAndQueries();
	AvailableValues = New ValueList;
	
	AvailableValues.LoadValues(AvailableTypesOfOperationsAndQueries.UnloadColumn("TypeOfOperationSynonym"));
	For Each AvailableValue In AvailableValues Do 
		AvailableValue.Presentation = AvailableValue.Value;
	EndDo;
	
	Return AvailableValues;
EndFunction

Procedure AddOperationTypeAndRequest(Table, TypesOfOperationsAndSynonyms, OperationKind, NameOfRequestText)
	
	NewRow = Table.Add();
	NewRow.OperationKind = OperationKind;
	NewRow.TypeOfOperationSynonym = TypesOfOperationsAndSynonyms[OperationKind];
	NewRow.NameOfRequestText = NameOfRequestText;
	
EndProcedure

Function TypesOfOperationsAndSynonyms()
	
	TypesOfOperationsAndSynonyms = New Map;
	
	TypesOfOperationsAndSynonyms.Insert("GoodsInTransit", NStr("vi = 'Hàng đang chuyển';
																|ru = 'Товары в пути';
																|en = 'Goods in transit'; fa = 'کالاهای در راه';
																|it = 'Merci in transito';
																|pl = 'Wiersze pozycji w drodze';
																|tr = 'Transit ürünler'"));
	TypesOfOperationsAndSynonyms.Insert("UninvoicedDelivery", NStr("vi = 'Giao hàng chưa có hóa đơn';
																	|ru = 'Неотфактурованная поставка';
																	|en = 'GRNI'; fa = 'GRNI';
																	|it = 'Consegna non fatturata';
																	|pl = 'Niefakturowana dostawa';
																	|tr = 'Faturasız teslimat'"));
	
	Return TypesOfOperationsAndSynonyms;
	
EndFunction

Function QueryText()
	NumberOfConnectedRequests = 0;
	QueryText = "";
	
	Available2 = AvailableTypesOfOperationsAndQueries();
	QueryTexts = New Structure; 
	For Each Available In Available2 Do 
		QueryTexts.Insert(Available.NameOfRequestText, True);
	EndDo;
	
	DisplayGoodsEnRoute = QueryTexts.Property("QueryTextGoodsInTransit");
	WithdrawUnfacturedDeliveries = QueryTexts.Property("QueryTextUninvoicedDelivery");
	
	If DisplayGoodsEnRoute
		Or WithdrawUnfacturedDeliveries Then
		TemporaryTableQueryText = TemporaryTableQueryText(DisplayGoodsEnRoute, WithdrawUnfacturedDeliveries);
		ConnectRequest(QueryText, "", 0, TemporaryTableQueryText);
	EndIf;
	
	If DisplayGoodsEnRoute Then
		ConnectRequest(QueryText, QueryTextGoodsInTransit(), NumberOfConnectedRequests);
	EndIf;
	
	If WithdrawUnfacturedDeliveries Then
		ConnectRequest(QueryText, QueryTextUninvoicedDelivery(), NumberOfConnectedRequests);
	EndIf;
	
	Return QueryText;
EndFunction

#EndRegion

#EndIf