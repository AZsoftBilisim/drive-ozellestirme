#Region FormEventHandlers

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndCloseCompletion", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Title =
		NStr("vi = 'Tùy chỉnh đồng bộ mục tin của các đối tượng để trao đổi với ứng dụng di động ""1C:Đơn hàng""';
			|ru = 'Настройка синхронизации реквизитов объектов для обмена с мобильным приложением ""1С:Заказы""';
			|en = 'Set up object attribute synchronization for exchange with 1C:Orders mobile application'; fa = 'Set up object attribute synchronization for exchange with 1C:Orders mobile application';
			|it = 'Configurazione della sincronizzazione dei dettagli degli oggetti per lo scambio con l''app mobile ""1C:Orders""';
			|pl = 'Ustawienia synchronizacji atrybutów obiektów do wymiany z aplikacją mobilną ""1C:Orders""';
			|tr = '""1C:Orders"" mobil uygulaması ile değişim için nesne ayrıntılarının senkronizasyonunun ayarlanması'");
		
	MasterNode = ExchangePlans.MobileApplicationSalesOrders.ThisNode();
	MobileApplicationSalesOrdersOverridable.FillInTableOfSavedDetails(SavedExchangeDetails);
	FillInTreeOfExchangeObjects();
	FillInDetailsTable();
	
	Items.TreeOfExchangeObjects.CurrentRow = 1;
	CurObjectType_ = "Catalog.Products";
EndProcedure

#EndRegion

#Region EventHandlersFormTablesExchangeObjectTree

&AtClient
Procedure TreeOfExchangeObjectsOnActivateRow(Item)
	
	If Items.TreeOfExchangeObjects.CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurObjectType_ = Items.TreeOfExchangeObjects.CurrentData.ExchangeObject;
EndProcedure

#EndRegion

#Region FormCommands

&AtClient
Procedure SaveAndLoad(Command)
	
	WriteAndCloseCompletion(, New Structure("Close", True));
EndProcedure

&AtClient
Procedure Save(Command)
	
	WriteAndCloseCompletion(, New Structure("Close", False));
EndProcedure

&AtClient
Procedure OnlySelectedOnes(Command)
	
	Items.DetailsOfExchangeOnlySelectedOnes.Check = Not Items.DetailsOfExchangeOnlySelectedOnes.Check;
	OnlySelectedOnesServer(Items.DetailsOfExchangeOnlySelectedOnes.Check);
EndProcedure

&AtClient
Procedure OnlyAvailable(Command)
	
	Items.DetailsOfExchangeOnlyAvailable.Check = Not Items.DetailsOfExchangeOnlyAvailable.Check;
	OnlyAvailableServer(Items.DetailsOfExchangeOnlyAvailable.Check);
EndProcedure

#EndRegion

#Region Private

// Fills in a row in the table of transmitted Bank details.
// Parameters:
//  ObjectAttributes - ValueTable - table of object details;
//  Attribute - MetadataObjectAttribute, StandardAttributeDescription, ValueTableRow - ;
//  FullMetadataObjectName - String - ;
//  AlwaysParticipates - Boolean - .
//
&AtServer
Procedure AddAttributeToTable(ObjectAttributes, Attribute, FullMetadataObjectName, AlwaysParticipates = False)
		
	PropsString = ObjectAttributes.FindRows(New Structure("Attribute, ObjectName, ValueType",
		Attribute.Name, FullMetadataObjectName, Attribute.Type));
		
	If PropsString.Count() = 0 Then
		StringAttribute = ObjectAttributes.Add();
	Else
		StringAttribute = PropsString[0];
	EndIf;
	
	StringAttribute.Attribute = Attribute.Name;
	If TypeOf(StringAttribute.Attribute) = Type("String") Then
		StringAttribute.Presentation = Attribute.Presentation();
		Disabled = False;
	Else
		StringAttribute.Presentation = Attribute.Presentation;
		Disabled = Attribute.Disabled;
	EndIf;
	
	StringAttribute.AlwaysParticipates = AlwaysParticipates;
	StringAttribute.ObjectName = FullMetadataObjectName;
	StringAttribute.ValueType = Attribute.Type;
	
	Participates = False;
	
	If AlwaysParticipates Then
		Participates = True;
		Disabled = True;
	EndIf;
	
	If TypeNotAvailableForExchange(Attribute.Type) Then
		Participates = AlwaysParticipates;
		Disabled = True;
	EndIf;
	If Not StrFind(Attribute.Name, "Delete") = 0 Then
		Participates = False;
		Disabled = True;
	EndIf;
	
	If Not AlwaysParticipates Then
		Participates = ThisIsFromExchangeDescription(Attribute.Name, FullMetadataObjectName);
		AlwaysParticipates = Participates;
		If Not Disabled Then
			Disabled = Participates;
		EndIf;
		StringAttribute.AlwaysParticipates = AlwaysParticipates;
	EndIf;
	
	If Not AlwaysParticipates And Not Disabled Then
		SavedSetting = OneOfSavedSettings(Attribute, FullMetadataObjectName);
		Participates = SavedSetting.Participates;
		StringAttribute.UniquePropertyID = SavedSetting.UniquePropertyID;
	EndIf;
	
	StringAttribute.Participates = Participates;
	StringAttribute.Disabled = Disabled;
EndProcedure

&AtServer
Function AdditionalDetailsForMetadataObject(FullMetadataObjectName)
	
	Sets = New ValueList;
	If FullMetadataObjectName = "Catalog.Companies" Then
		Sets.Add(PropertyManager.PropertiesSetByName("Catalog_Companies"));
	ElsIf FullMetadataObjectName = "Catalog.Products" Then
		Sets = PropertySetsForProducts();
	ElsIf FullMetadataObjectName = "Catalog.Partners" Then
		Sets = PropertyManagerOverridable.GetPropertySetsForPartners(True, False, False, False);
	ElsIf FullMetadataObjectName = "Document.SalesOrder" Then
		Sets.Add(PropertyManager.PropertiesSetByName("Document_SalesOrder"));
	ElsIf FullMetadataObjectName = "Document.RequestForReturnOfGoodsFromCustomer" Then
		Sets.Add(PropertyManager.PropertiesSetByName("Document_RequestForReturnOfGoodsFromCustomer"));
	EndIf;
	
	Query = New Query("SELECT
	|	AdditionalAttributeSets.Property AS Name,
	|	AdditionalAttributeSets.Property.ValueType AS Type,
	|	AdditionalAttributeSets.Property.Presentation AS Presentation,
	|	CASE
	|		WHEN NOT AdditionalAttributeSets.Property.Available
	|				OR NOT AdditionalAttributeSets.Property.isVisible
	|				OR AdditionalAttributeSets.Property.DeletionMark
	|				OR AdditionalAttributeSets.DeletionMark
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Disabled
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AdditionalAttributeSets
	|WHERE
	|	AdditionalAttributeSets.Ref IN(&Sets)");
	
	Query.SetParameter("Sets", Sets);
	
	Return Query.Execute().Unload();
EndFunction

&AtClient
Procedure WriteAndCloseCompletion(Result = Undefined, AdditionalParameters = Undefined) Export
	
	Cancel = False;
	WriteSettings(Cancel);
	If Not Cancel Then
		Modified = False;
		If AdditionalParameters = Undefined Then
			Close();
		Else
			If AdditionalParameters.Property("Close") And AdditionalParameters.Close Then
				Close();
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure WriteSettings(Cancel)
	
	NewSettings1 = DetailsOfExchange.Unload(New Structure("AlwaysParticipates, Disabled", False, False),
		"Attribute, Participates, ObjectName, ValueType, UniquePropertyID, Presentation");
	For Each String In NewSettings1 Do
		If Not ValueIsFilled(String.UniquePropertyID) Then
			If TypeOf(String.Attribute) = Type("String") Then
				String.UniquePropertyID = New UUID;
			Else
				String.UniquePropertyID = String.Attribute.UUID();
			EndIf;
		EndIf;
	EndDo;
	BeginTransaction(DataLockControlMode.Managed);
	Try
		MainNodeObject = MasterNode.GetObject();
		LockDataForEdit(MainNodeObject.Ref);
		MainNodeObject.ExchangeAttributeSettings = New ValueStorage(NewSettings1, New Deflation(9));
		MainNodeObject.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("vi = 'Bản ghi tùy chỉnh';
							|ru = 'Запись настроек';
							|en = 'Save settings'; fa = 'ذخیره تنظیمات';
							|it = 'Registra le impostazioni';
							|pl = 'Zapisanie ustawień';
							|tr = 'Ayarları kaydet'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
				DetailErrorDescription(ErrorInfo()));
		CommonClientServer.MessageToUser(ErrorDescription(),,,, Cancel);
	EndTry;
EndProcedure

&AtServer
Procedure FillInTreeOfExchangeObjects()
	
	CollectionOfExchangeObjects = TreeOfExchangeObjects.GetItems();
	
	StringCatalogs = CollectionOfExchangeObjects.Add();
	StringCatalogs.ExchangeObject = "Catalogs";
	StringCatalogs.Presentation = NStr("vi = 'Danh mục';
										|ru = 'Справочники';
										|en = 'Catalogs'; fa = 'فهرست‌ها';
										|it = 'Directory';
										|pl = 'Catalogs';
										|tr = 'Kataloglar'", CommonClientServer.DefaultLanguageCode());
	
	CollectionOfCatalogObjects = StringCatalogs.GetItems();
	
	RowObjects = CollectionOfCatalogObjects.Add();
	RowObjects.ExchangeObject = "Catalog.Products";
	RowObjects.Presentation = NStr("vi = 'Mặt hàng';
									|ru = 'Номенклатура';
									|en = 'Items'; fa = 'اقلام';
									|it = 'Articolo';
									|pl = 'Items';
									|tr = 'Öğe'", CommonClientServer.DefaultLanguageCode());
	
	RowObjects = CollectionOfCatalogObjects.Add();
	RowObjects.ExchangeObject = "Catalog.Partners";
	RowObjects.Presentation = NStr("vi = 'Bạn hàng';
									|ru = 'Партнеры';
									|en = 'Partners'; fa = 'شرکای تجاری';
									|it = 'Partner';
									|pl = 'Partners';
									|tr = 'İş ortakları'", CommonClientServer.DefaultLanguageCode());
	
	RowObjects = CollectionOfCatalogObjects.Add();
	RowObjects.ExchangeObject = "Catalog.Companies";
	RowObjects.Presentation = NStr("vi = 'Doanh nghiệp';
									|ru = 'Организации';
									|en = 'Companies'; fa = 'شرکت‌ها';
									|it = 'Aziende';
									|pl = 'Companies';
									|tr = 'İş yerleri'", CommonClientServer.DefaultLanguageCode());
	
	StringDocuments = CollectionOfExchangeObjects.Add();
	StringDocuments.ExchangeObject = "Documents";
	StringDocuments.Presentation = NStr("vi = 'Chứng từ';
										|ru = 'Документы';
										|en = 'Documents'; fa = 'اسناد';
										|it = 'Documenti';
										|pl = 'Dokumenty';
										|tr = 'Belgeler'", CommonClientServer.DefaultLanguageCode());
	
	CollectionOfObjectsDocuments = StringDocuments.GetItems();
	
	RowObjects = CollectionOfObjectsDocuments.Add();
	RowObjects.ExchangeObject = "Document.SalesOrder";
	RowObjects.Presentation = NStr("vi = 'Đơn hàng của khách';
									|ru = 'Заказ клиента';
									|en = 'Sales order'; fa = 'سفارش فروش';
									|it = 'Ordine del cliente';
									|pl = 'Zamówienie klienta';
									|tr = 'Satış siparişi'", CommonClientServer.DefaultLanguageCode());
	
	RowObjects = CollectionOfObjectsDocuments.Add();
	RowObjects.ExchangeObject = "Document.RequestForReturnOfGoodsFromCustomer";
	RowObjects.Presentation = NStr("vi = 'Giấy đề nghị trả hàng từ người mua';
									|ru = 'Заявка на возврат товаров от клиента';
									|en = 'Sales return request'; fa = 'درخواست برگشت از فروش';
									|it = 'Richiesta di reso della merce dal cliente';
									|pl = 'Wniosek o zwrot towarów od klienta';
									|tr = 'Müşteriden mal iade talebi'",
		CommonClientServer.DefaultLanguageCode());
EndProcedure

&AtServer
Procedure FillInDetailsTable()
	
	TreeRowsCollection = TreeOfExchangeObjects.GetItems();
	
	For Each TreeRow In TreeRowsCollection Do
		MetadataRowCollection = TreeRow.GetItems();
		For Each String In MetadataRowCollection Do
			FillInTableOfDetailsForMetadataObject(String.ExchangeObject);
		EndDo;
	EndDo;
EndProcedure

&AtServer
Procedure FillInTableOfDetailsForMetadataObject(FullMetadataObjectName)
	
	MetadataObject = Metadata.FindByFullName(FullMetadataObjectName);
	
	For Each Attribute In MetadataObject.StandardAttributes Do
		AddAttributeToTable(DetailsOfExchange, Attribute, FullMetadataObjectName, True);
	EndDo;
	
	For Each Attribute In MetadataObject.Attributes Do
		AddAttributeToTable(DetailsOfExchange, Attribute, FullMetadataObjectName);
	EndDo;
	
	AdditionalAttributes = AdditionalDetailsForMetadataObject(FullMetadataObjectName);
	
	For Each Attribute In AdditionalAttributes Do
		AddAttributeToTable(DetailsOfExchange, Attribute, FullMetadataObjectName);
	EndDo;
EndProcedure

&AtServer
Function PropertySetsForProducts()
	
	Sets = New ValueList;
	
	PropertiesSet = PropertyManager.PropertiesSetByName("Catalog_Products_Overall");
	Sets.Add(PropertiesSet);
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED DISTINCT
	|	ItemKinds.PropertiesSet
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|WHERE
	|	NOT ItemKinds.DeletionMark
	|	AND NOT ItemKinds.PropertiesSet.DeletionMark
	|	AND NOT ItemKinds.PropertiesSet = VALUE(Catalog.AdditionalAttributesAndInfoSets.EmptyRef)";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Sets;
	EndIf;
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		Sets.Add(Selection.PropertiesSet);
	EndDo;
	
	Return Sets;
EndFunction

&AtServer
Function TypeNotAvailableForExchange(AttributeValueType)
	
	// We unload the details only of a non-composite type containing simple types and
	// types "Reference Link.The values of the properties of the objects" and "Reference link.The values of the properties of the objects of the Hierarchy".
	If AttributeValueType.Types().Count() = 1
		And (AttributeValueType.ContainsType(Type("Boolean"))
			Or AttributeValueType.ContainsType(Type("Date"))
			Or AttributeValueType.ContainsType(Type("String"))
			Or AttributeValueType.ContainsType(Type("Number"))
			Or AttributeValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
			Or AttributeValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy"))) Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction

&AtServer
Procedure OnlySelectedOnesServer(Check)
	
	ConditionalAppearanceElement = ThisForm.ConditionalAppearance.Items.Get(3);
	ConditionalAppearanceElement.Use = Check;
EndProcedure

&AtServer
Procedure OnlyAvailableServer(Check)
	
	ConditionalAppearanceElement = ThisForm.ConditionalAppearance.Items.Get(4);
	ConditionalAppearanceElement.Use = Check;
EndProcedure

&AtServer
Function OneOfSavedSettings(Attribute, FullMetadataObjectName)
	
	SavedSetting = New Structure("Participates, UniquePropertyID", False, "");
	PropsString = SavedExchangeDetails.FindRows(New Structure("Attribute, ObjectName, ValueType",
		Attribute.Name, FullMetadataObjectName, Attribute.Type));
		
	If Not PropsString.Count() = 0 Then
		FillPropertyValues(SavedSetting, PropsString[0]);
		If Not ValueIsFilled(SavedSetting.UniquePropertyID) Then
			If TypeOf(Attribute.Name) = Type("String") Then
				SavedSetting.UniquePropertyID = New UUID;
			Else
				SavedSetting.UniquePropertyID = Attribute.Name.UUID();
			EndIf;
		EndIf;
	EndIf;
	
	Return SavedSetting;
EndFunction

&AtServer
Function ThisIsFromExchangeDescription(Var_AttributeName, FullMetadataObjectName)
	
	ArrayOfUsedProps = New Array;
	If FullMetadataObjectName = "Catalog.Products" Then
		ArrayOfUsedProps.Add("VATRate");
		ArrayOfUsedProps.Add("SKU");
		ArrayOfUsedProps.Add("WeightUnitOfMeasure");
		ArrayOfUsedProps.Add("WeightDenominator");
		ArrayOfUsedProps.Add("WeightUse");
		ArrayOfUsedProps.Add("YouCanSpecifyWeightInDocuments");
		ArrayOfUsedProps.Add("WeightNumerator");
		ArrayOfUsedProps.Add("ProductKind");
		ArrayOfUsedProps.Add("UnitOfMeasure");
		ArrayOfUsedProps.Add("DescriptionFull");
		ArrayOfUsedProps.Add("LongDesc");
		ArrayOfUsedProps.Add("PicturesFile");
		ArrayOfUsedProps.Add("PriceGroup");
	ElsIf FullMetadataObjectName = "Catalog.Partners" Then
		ArrayOfUsedProps.Add("Client");
	ElsIf FullMetadataObjectName = "Catalog.Companies" Then
		ArrayOfUsedProps.Add("Prefix");
		ArrayOfUsedProps.Add("TIN");
		ArrayOfUsedProps.Add("CRTR");
		ArrayOfUsedProps.Add("DescriptionFull");
		ArrayOfUsedProps.Add("LegalEntityIndividual");
		ArrayOfUsedProps.Add("SeriesAndNumber");
		ArrayOfUsedProps.Add("SertificateDateOfIssue");
	ElsIf FullMetadataObjectName = "Document.SalesOrder" Then
		ArrayOfUsedProps.Add("DocumentAmount");
		ArrayOfUsedProps.Add("PriceIncludesVAT");
		ArrayOfUsedProps.Add("NotShipInInstallments");
		ArrayOfUsedProps.Add("MaximumRowCode");
		ArrayOfUsedProps.Add("Approved");
		ArrayOfUsedProps.Add("AmountPrepaymentBeforeGoodsIssue");
		ArrayOfUsedProps.Add("AmountOfPrepaymentBeforeShipment");
		ArrayOfUsedProps.Add("DateOfShipment");
		ArrayOfUsedProps.Add("DeliveryAddress");
		ArrayOfUsedProps.Add("DiscountsAreCalculated");
		ArrayOfUsedProps.Add("Comment");
		ArrayOfUsedProps.Add("DeliveryTimeFrom");
		ArrayOfUsedProps.Add("DeliveryTimeTo");
		ArrayOfUsedProps.Add("DeliveryAddressFieldValues");
		ArrayOfUsedProps.Add("AdditionalDeliveryInformation");
	ElsIf FullMetadataObjectName = "Document.RequestForReturnOfGoodsFromCustomer" Then
		ArrayOfUsedProps.Add("DocumentAmount");
		ArrayOfUsedProps.Add("RequestedDeliveryDate");
		ArrayOfUsedProps.Add("PriceIncludesVAT");
		ArrayOfUsedProps.Add("DateOfReceipt");
		ArrayOfUsedProps.Add("DeliveryAddress");
		ArrayOfUsedProps.Add("Comment");
		ArrayOfUsedProps.Add("DeliveryTimeFrom");
		ArrayOfUsedProps.Add("DeliveryTimeTo");
		ArrayOfUsedProps.Add("DeliveryAddressFieldValues");
		ArrayOfUsedProps.Add("AdditionalDeliveryInformation");
	EndIf;
	
	FoundAttribute = ArrayOfUsedProps.Find(Var_AttributeName);
	
	Return Not FoundAttribute = Undefined;
EndFunction

#EndRegion
