
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		If Parameters.ChoiceMode Then
			FillInFieldsBasedOnParameters(Parameters.ChoiceParameters);
		Else
			FillInFieldsBasedOnParameters(Parameters);
		EndIf;
		
	EndIf;
		
	TheMetadataNameOfTheOwner = Object.ItemOwner.Metadata().Name;
	
	If Object.QuantityInBaseUnitOfMeasure <> 1 Then
		PackageKind = "Package";
	ElsIf Object.NumberOfPackages <> 1 Then
		PackageKind = "Unpacking";
	Else
		PackageKind = "Package";
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("PackageKind"                        , PackageKind);
	AdditionalParameters.Insert("PackageName"               , Object.PackageName);
	AdditionalParameters.Insert("BaseUnitOfMeasureDescription", Object.BaseUnitOfMeasureDescription);
	AdditionalParameters.Insert("BaseUnitOfMeasureARCMUCode"     , Object.BaseUnitOfMeasureARCMUCode);
	AdditionalParameters.Insert("QuantityInBaseUnitOfMeasure"  , Object.QuantityInBaseUnitOfMeasure);
	AdditionalParameters.Insert("NumberOfPackages"                 , Object.NumberOfPackages);
	
	TitleStart    = "";
	TitleEnd = "";
	
	ChangeDisplayOfPackageView(Items, AdditionalParameters, TitleStart, TitleEnd);
	
	TitleStart    = StringFunctions.FormattedString(TitleStart);
	TitleEnd = StringFunctions.FormattedString(TitleEnd);
	
	SetUnitPresentationTitle(Items, TitleStart, TitleEnd);
	
	ChangeOwnerLabel();

	SetPropertiesOfRedefinedFormElements();
	
	If ValueIsFilled(Parameters.Key) Then
		SetEditingPermission(False);
	EndIf;

	OnReadCreateAtServer();

	ProductCrossReferencesMappingOverridable.WhenCreatingCounterpartyProductItemFormOn_Server(
		ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	ProductCrossReferencesMappingClientOverridable.NotificationProcessing_FormOfCounterpartyProductItem(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	ProductCrossReferencesMappingClientOverridable.WhenOpening_FormOfCounterpartyProductItem(ThisObject, Cancel);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();

	ProductCrossReferencesMappingOverridable.WhenReadingOnServer_FormOfCounterpartyProductItem(
		ThisForm, CurrentObject);

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	Object.ItemOwner = Object.Owner;
	
	If Not ValueIsFilled(Object.DescriptionFull) Then
		
		Object.DescriptionFull = Object.ItemName
			+ ?(ValueIsFilled(Object.ItemVariantName), " (" + Object.ItemVariantName + ")", "")
			+ ?(ValueIsFilled(Object.PackageName), ", " + Object.PackageName, "");
			
	EndIf;
		
	Object.Description = Object.DescriptionFull;

	ProcessIDFilling(Cancel);
	
	If Not Object.Invalid And Not Object.DeletionMark
		And (IsBlankString(Object.PackageName) Or IsBlankString(Object.BaseUnitOfMeasureDescription))
		And ValueIsFilled(Object.PackageID) Then
		Text =  NStr("vi = 'Cần điền tên gọi đơn vị tính và đóng gói.';
					|ru = 'Необходимо заполнить наименование единицы измерения и упаковки.';
					|en = 'Fill in unit of measure and packaging unit name.'; fa = 'Fill in unit of measure and packaging unit name.';
					|it = 'É necessario compilare il nome dell''unità di misura e imballaggio.';
					|pl = 'Należy wypełnić nazwę jednostki miary i opakowania.';
					|tr = 'Ölçü biriminin tanımı ve paketleme ünitesi doldurulmalı.'");
		CommonClient.MessageToUser(Text, , , , Cancel);
		Return;
	EndIf;

	If ValueIsFilled(Object.Products)
		And Not ValueIsFilled(Object.Package) And ValueIsFilled(DefaultUnitOfMeasurement) Then
		Object.Package = DefaultUnitOfMeasurement;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.OtherItemsBarcodes = 
		StrConcat(CurrentObject.OtherProductsBarcodes.Unload().UnloadColumn("Barcode"), ",");

	ProductCrossReferencesMappingOverridable.BeforeRecordingOnServer_FormOfCounterpartyProductItem(
		ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ProductCrossReferencesMappingClientOverridable.AfterWriting_FormOfCounterpartyProductItem(
		ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	ProductCrossReferencesMappingOverridable.AfterRecordingOnServer_FormOfCounterpartyProductItem(
		ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductsOnChange(Item)
	
	ProductsOnChangeServer();
	
EndProcedure

&AtClient
Procedure OwnerSLabelClick(Item)
		
	CallbackDescription = New CallbackDescription("ChangeOwnerCompletion", ThisObject);
	
	OpeningParameters = New Structure();
	OpeningParameters.Insert("CurrentRow", Object.ItemOwner);
	OpeningParameters.Insert("ChoiceMode"  , True);
	
	OpenForm(StrTemplate("Catalog.%1.ChoiceForm",TheMetadataNameOfTheOwner),
		OpeningParameters,
		ThisForm,
		, , ,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChangeTheUnitOfMeasurement(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("PackageKind"                        , PackageKind);
	FormParameters.Insert("PackageName"               , Object.PackageName);
	FormParameters.Insert("BaseUnitOfMeasureDescription", Object.BaseUnitOfMeasureDescription);
	FormParameters.Insert("BaseUnitOfMeasureARCMUCode"     , Object.BaseUnitOfMeasureARCMUCode);
	FormParameters.Insert("QuantityInBaseUnitOfMeasure"  , Object.QuantityInBaseUnitOfMeasure);
	FormParameters.Insert("NumberOfPackages"                 , Object.NumberOfPackages);
	
	ClosingNotification = New CallbackDescription("ChangeUnitOfMeasurementEnd", ThisObject);

	OpenForm("Catalog.ProductCrossReferences.Form.CreatePackage", 
		FormParameters, ThisForm,,,, ClosingNotification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure IdOnChange(Item)
	
	ProcessIDFilling();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	ProductCrossReferencesMappingClientOverridable.Attachable_ExecuteIntegrationCommand_CounterpartyNomenclatures(
		ThisForm, Command, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	PartnersProductsClient.Attachable_ExecuteOverridableCommand_CounterpartyNomenclatures(ThisObject, Command);
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	PartnersProductsClient.Attachable_CommandOfAttachedFilesPanel_CounterpartyNomenclatures(
		ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	PartnersProductsClient.Attachable_PreviewFieldCheckDragging_CounterpartyNomenclatures(
		ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	PartnersProductsClient.Attachable_PreviewFieldDrag_CounterpartyNomenclatures(
		ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	PartnersProductsClient.Attachable_PreviewFieldClick_CounterpartyNomenclatures(
		ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure EnableEdit(Command)
	
	ShowQuestionAboutEditingPermission();
	
EndProcedure

&AtClient
Procedure PictureOpeningOfTheOwnerClick(Item)
	
	ShowValue(,Object.ItemOwner);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetPropertiesOfRedefinedFormElements()
	
	MappingMetadata = ProductCrossReferencesMappingInternal.ProductMappingMetadata();
		
	If Not ValueIsFilled(Object.Ref) Then
		CaptionPresentation = NStr("vi = '(Tạo mới)';
									|ru = '(Создание)';
									|en = '(Create)'; fa = '(Create)';
									|it = '(creazione)';
									|pl = '(utworzenie)';
									|tr = '(Oluşturma)'");
	Else
		CaptionPresentation = Object.Description;
	EndIf;
	
	Title = StrTemplate(NStr("vi = '%1: %2';
							|ru = '%1: %2';
							|en = '%1: %2'; fa = '%1: %2';
							|it = '%1: %2';
							|pl = '%1: %2';
							|tr = '%1: %2'"), MappingMetadata.ItemProductsAndPresentation, CaptionPresentation);

	Items.Products.Title   = MappingMetadata.ProductObjectPresentation;
	Items.Characteristic.Title = MappingMetadata.FeaturePresentationOfObject;
	Items.Package.Title       = MappingMetadata.PackagingObjectPresentation;
	
	If Metadata.DefinedTypes.EDLProducts.Type.Types().Count() > 1 
		And Not ValueIsFilled(Items.Products.TypeRestriction) Then
		TypesUsed = ProductCrossReferencesMappingCached.TypesOfBADNomenclatureUsed(); 
		CommonClientServer.SetFormItemProperty(Items, "Products", "TypeRestriction",
			New TypeDescription(TypesUsed));
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductsOnChangeServer()
	
	ProductCrossReferencesMappingInternal.ProductsOnChange(ThisObject, "Object", 
		DefaultUnitOfMeasurement);
	
EndProcedure

&AtServerNoContext
Function DuplicateCounterpartyProducts(Val Ref, Val ItemOwner, Val Id)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ProductCrossReferences.Ref AS ProductCrossReference
	|FROM
	|	Catalog.ProductCrossReferences AS ProductCrossReferences
	|WHERE
	|	ProductCrossReferences.ItemOwner = &ItemOwner
	|	AND NOT ProductCrossReferences.IsFolder
	|	AND NOT ProductCrossReferences.DeletionMark
	|	AND ProductCrossReferences.Ref <> &Ref
	|	AND NOT ProductCrossReferences.Invalid
	|	AND ProductCrossReferences.Id = &Id";
	
	Query.SetParameter("ItemOwner", ItemOwner);
	Query.SetParameter("Id"       , Id);
	Query.SetParameter("Ref"              , Ref);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Undefined;
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		Return Selection.ProductCrossReference;
	EndIf;
	
EndFunction

&AtServer
Procedure OnReadCreateAtServer()
	
	If Parameters.Property("CopyingValue")
		And ValueIsFilled(Parameters.CopyingValue) Then
		ClearFieldsThatAreNotAllowedForCopying();
	EndIf;
	
	ProductsOnChangeServer();
	
EndProcedure

&AtClient
Procedure ChangeOwnerCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.Owner             = Result;
	Object.ItemOwner = Result;
	Items.OwnerSLabel.Title = String(Object.ItemOwner);
	
EndProcedure

&AtServer
Procedure ChangeOwnerLabel()
	
	If ValueIsFilled(Object.ItemOwner) Then
		Items.OwnerSLabel.Title = String(Object.ItemOwner);
	Else
		Items.OwnerSLabel.Title = New FormattedString(NStr("vi = '<chỉ ra chủ sở hữu>';
															|ru = '<указать владельца>';
															|en = '<specify owner>'; fa = '<تعیین مالک>';
															|it = '<indicare proprietario>';
															|pl = '<podaj właściciela>';
															|tr = '<sahibi belirt>'"), , StyleColors.ImportantDataColorEDL, , );
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeUnitOfMeasurementEnd(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(Object, Result);
	PackageKind = Result.PackageKind;
	
	TitleStart    = "";
	TitleEnd = "";
	
	ChangeDisplayOfPackageView(Items, Result, TitleStart, TitleEnd);
	
	TitleStart    = StringFunctionsClient.FormattedString(TitleStart);
	TitleEnd = StringFunctionsClient.FormattedString(TitleEnd);
	
	SetUnitPresentationTitle(Items, TitleStart, TitleEnd);

EndProcedure

&AtClientAtServerNoContext
Procedure ChangeDisplayOfPackageView(Items, Parameters, TitleStart, TitleEnd)
	
	If Not ValueIsFilled(Parameters.BaseUnitOfMeasureDescription) Then
		Items.PackagingViewPages.CurrentPage = Items.SpecifyPackagingPage;
		Return;
	ElsIf Not ProductCrossReferencesMappingInternalClientServer.PackagingAndBaseUnitAreDifferent(Parameters) Then
		Items.PackagingViewPages.CurrentPage = Items.BaseUnitPage;
	Else
		Items.PackagingViewPages.CurrentPage = Items.UnitOfMeasurementPages;
	EndIf;
	
	If Parameters.PackageKind = "Package" Then
		
		Items.PackagingTypePages.CurrentPage = Items.PagePackaging;
		
		Items.NumberOfPackages.Visible                = False;
		Items.QuantityInBaseUnitOfMeasure.Visible = True;
		
		TitleStart    = StrTemplate(NStr("vi = '<b>1 %1</b> bao gồm';
										|ru = '<b>1 %1</b> состоит из';
										|en = '<b>1 %1</b> consists of'; fa = '<b>1 %1</b> consists of';
										|it = '<b>1 %1</b> состоит из';
										|pl = '<b>1 %1</b> consists of';
										|tr = '<b>1 %1</b> oluşur'"), Parameters.PackageName);
		TitleEnd = StrTemplate("<b>%1</b>", Parameters.BaseUnitOfMeasureDescription);
		
	ElsIf Parameters.PackageKind = "Unpacking" Then
		
		Items.PackagingTypePages.CurrentPage = Items.UnpackingPage;
		
		Items.NumberOfPackages.Visible                = True;
		Items.QuantityInBaseUnitOfMeasure.Visible = False;
		
		TitleStart    = StrTemplate("<b>%1</b>", Parameters.PackageName);
		TitleEnd = StrTemplate(NStr("vi = 'bao gồm <b>1 %1</b>';
									|ru = 'содержится в <b>1 %1</b>';
									|en = 'contained in <b>1 %1</b>'; fa = 'contained in <b>1 %1</b>';
									|it = 'содержится в <b>1 %1</b>';
									|pl = 'contained in <b>1 %1</b>';
									|tr = '<b> 1 %1</b>''de bulunuyor'"), Parameters.BaseUnitOfMeasureDescription);

	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetUnitPresentationTitle(Items, TitleStart, TitleEnd)
	
	Items.RepresentationOfTheNumeratorDenominatorBeginning.Title     = TitleStart;
	Items.RepresentationOfTheNumeratorDenominatorEnding.Title  = TitleEnd;
	Items.RepresentationOfTheNumeratorDenominatorEnding1.Title = TitleEnd;
	
EndProcedure

&AtServerNoContext
Procedure CheckIDAndBreakItIntoPieces(Val Ref, Val ItemOwner, ProductCrossReference, Id,
		Val IDFillingIsRequired, Val DoubleCheckRequired)
	
	If IDFillingIsRequired Then
		
		Id = ProductCrossReferencesMapping.ProductIDByLine(Id, 300);
	
	EndIf;
	
	If DoubleCheckRequired Then
		ProductCrossReference = DuplicateCounterpartyProducts(Ref, ItemOwner, Id);
	EndIf;
	
EndProcedure

&AtClient
Function IdentifiersDividedIntoParts(Val Id)
	
	IDs = New Structure;
	IDs.Insert("ProductsIdentifier"  , "");
	IDs.Insert("ItemVariantID", "");
	IDs.Insert("PackageID"      , "");
	
	ProductCrossReferencesMappingClientServer.SplitIDIntoParts(Id, IDs);

	Return IDs;
	
EndFunction

&AtClient
Procedure ProcessIDFilling(Cancel = False)
	
	Id                     = "";
	ProductCrossReference           = Undefined;
	IDFillingIsRequired = False;
	
	If Not ValueIsFilled(Object.Id) Then
		Id = Object.ItemName + "#" + Object.ItemVariantName + "#" + Object.PackageName;
		IDFillingIsRequired = True;
	Else
		Id = Object.Id;
	EndIf;
	
	DoubleCheckRequired = Not Object.Invalid And Not Object.DeletionMark;
	
	CheckIDAndBreakItIntoPieces(Object.Ref, Object.ItemOwner, ProductCrossReference,
		Id, IDFillingIsRequired, DoubleCheckRequired);
	
	If IDFillingIsRequired Then
		Object.Id = Id;
	EndIf;	

	IDs = IdentifiersDividedIntoParts(Object.Id);
	Object.ProductsIdentifier   = IDs.ProductsIdentifier;
	Object.ItemVariantID = IDs.ItemVariantID;
	Object.PackageID       = IDs.PackageID;
	
	If ValueIsFilled(ProductCrossReference) Then
		Text = StrTemplate(NStr("vi = 'Đã tìm thấy mặt hàng ""%1"" mà có đặt tên gọi tương tự %2.';
								|ru = 'Найдена номенклатура ""%1"", для которой задан аналогичный идентификатор %2.';
								|en = 'Found item ""%1"" with the same ID %2.'; fa = 'Found item ""%1"" with the same ID %2.';
								|it = 'Trovato articolo ""%1"" con identificativo analogo %2 impostato.';
								|pl = 'Znaleziono pozycję ""%1"", dla której jest zadany analogiczny identyfikator %2.';
								|tr = '%2 benzer tanımlayıcının verildiği ""%1"" öğesi bulundu.'"),
			ProductCrossReference, Object.Id);
		CommonClient.MessageToUser(Text, ProductCrossReference, , , Cancel);
		Object.Id               = "";
		Object.ProductsIdentifier   = "";
		Object.ItemVariantID = "";
		Object.PackageID       = "";
		If Not ValueIsFilled(Object.Ref) Then
			Return;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowQuestionAboutEditingPermission() 
	
	Template = NStr("vi = 'Cho phép chỉnh sửa dữ liệu %1?';
					|ru = 'Разрешить редактирование данных %1?';
					|en = 'Allow %1 data editing?'; fa = 'Allow %1 data editing?';
					|it = 'Consentire la modifica dei dati %1?';
					|pl = 'Zezwalać edycję danych %1?';
					|tr = '%1 veri düzenlemeye izin ver?'");
	QueryText = StrTemplate(Template, Object.ItemOwner);
	ResponseHandler = New CallbackDescription("ProcessIssueOfEditingPermission", ThisObject);
	ShowQueryBox(ResponseHandler, QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure ProcessIssueOfEditingPermission(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		SetEditingPermission(True);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetEditingPermission(Val Enable)
	
	Items.GroupCounterpartyData.ReadOnly      = Not Enable;
	Items.DecorationChangeTheUnitOfMeasurement.Visible = Enable;
	Items.DecorationOfEmptyPackaging.Enabled         = Enable;
	Items.OwnerSLabel.Enabled                = Enable;
	
EndProcedure

&AtServer
Procedure FillInFieldsBasedOnParameters(FormParameters)
	
	ItemOwner = Undefined;
	If FormParameters.Property("ItemOwner") Then
		ItemOwner = FormParameters.ItemOwner;
	EndIf;
	
	If Not ValueIsFilled(ItemOwner)
			And Parameters.ChoiceParameters.Property("ItemOwner") Then
		ItemOwner = Parameters.ChoiceParameters.ItemOwner;
	EndIf;
	
	If ValueIsFilled(ItemOwner) Then
		Object.ItemOwner = ItemOwner;
		Object.Owner             = ItemOwner;
	EndIf;
	
	InformationSecurityProducts = New Structure;
	InformationSecurityProducts.Insert("Products"  , Undefined);
	InformationSecurityProducts.Insert("Characteristic", Undefined);
	InformationSecurityProducts.Insert("Package"      , Undefined);
	
	ProductsFilledIn = False;
	
	If FormParameters.Property("Products") Then
		Object.Products             = FormParameters.Products;
		Object.ItemName = FormParameters.Products;
		InformationSecurityProducts.Products     = FormParameters.Products;
		ProductsFilledIn           = True;
	EndIf;
	
	If FormParameters.Property("Characteristic") Then
		Object.Characteristic             = FormParameters.Characteristic;
		Object.ItemVariantName = FormParameters.Characteristic;
		InformationSecurityProducts.Characteristic     = FormParameters.Characteristic;
	EndIf;
	
	If FormParameters.Property("DefaultUnitOfMeasurement") Then
		DefaultUnitOfMeasurement = FormParameters.DefaultUnitOfMeasurement;
	EndIf;
	
	If FormParameters.Property("Package") Then
		Object.Package             = FormParameters.Package;
		InformationSecurityProducts.Package     = FormParameters.Package;
		
		If ProductsFilledIn Then
			
			If Not ValueIsFilled(DefaultUnitOfMeasurement) Then
				ProductCrossReferencesMappingOverridable.BasicUnitOfProductMeasurement(
					Object.Products, DefaultUnitOfMeasurement);
			EndIf;
			
			If Not ValueIsFilled(Object.Package) Then
				Object.Package = DefaultUnitOfMeasurement;
			EndIf;
		EndIf;
		
		PropertiesOfInformationSecurityProducts_ = ProductCrossReferencesMappingClientServer.NewPackagingProperties();
		ProductCrossReferencesMappingOverridable.WhenDeterminingPropertiesOfPackagingUnitsOfMeasurementOfNomenclature(
			Object.Package, Object.Products, PropertiesOfInformationSecurityProducts_);
		
		FillPropertyValues(Object, PropertiesOfInformationSecurityProducts_);
		
	EndIf;

	If ProductsFilledIn Then
		OtherProductsBarcodes = New Array();
		ProductCrossReferencesMappingOverridable.WhenDeterminingBarcodesOfCounterpartySProductRange(
			InformationSecurityProducts, Object.Barcode, OtherProductsBarcodes);

		If ValueIsFilled(OtherProductsBarcodes) Then
			For Each ItemsBarcode In OtherProductsBarcodes Do
				NewBarcode = Object.OtherProductsBarcodes.Add();
				NewBarcode.Barcode = ItemsBarcode;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearFieldsThatAreNotAllowedForCopying()
	
	Object.Id               = "";
	Object.ProductsIdentifier   = "";
	Object.ItemVariantID = "";
	Object.PackageID       = "";
	Object.Invalid              = False;
	Object.DeletionMark             = False;
	
EndProcedure

#EndRegion

