#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	SetConditionalAppearance();
	
	TypesArray = Catalogs.QualityCertificates.CreateListToSelectCertificateTypes();
	Items.CertificateType.ChoiceList.LoadValues(TypesArray);
	
	If Parameters.Property("CertificateType") Then
		Object.CertificateType = Parameters.CertificateType;
	EndIf;
	
	If Parameters.Property("ProductKind") Then
		ProductKind = Parameters.ProductKind;
	EndIf;
	
	If Parameters.Property("Products") Then
		Products = Parameters.Products;
	EndIf;
	
	Items.ScopeCharacteristic.Visible = GetFunctionalOption("UseItemVariants");
	Items.ScopeSeries.Visible          = GetFunctionalOption("UseItemsBatch");
	
	ImageCounter = NStr("vi = '0 / 0';
						|ru = '0 из 0';
						|en = '0 out of 0'; fa = '0 out of 0';
						|it = '0 da 0';
						|pl = '0 z 0';
						|tr = '0''dan 0'");
	
	If Not ValueIsFilled(Object.Ref) Then
		
		ScopeOption = "SpecificProduct";
		
		If ValueIsFilled(Parameters.CopyingValue) Then
			FillInScope(Parameters.CopyingValue);
		ElsIf ValueIsFilled(Products) Then
			ProductsOnChangeServer();
		ElsIf ValueIsFilled(ProductKind) Then
			ScopeOption = "ProductKind";
			
			Items.ScopePages.CurrentPage = Items.PageProductKind;
			
			ProductsOnChangeServer();
		Else
			ProductsOnChangeServer();
		EndIf;
		
		OnReadCreateAtServer(False);
		
	Else
		UpdateImageTable();
	EndIf;
	
	If Not AccessRight("Update", Metadata.Catalogs.QualityCertificates) Then
		Items.ImageCommandBar.Enabled = False;
		Items.Scope.CommandBar.Enabled = False;
		Items.Scope.ContextMenu.Enabled = False;
		Items.ScopeOption.Enabled = False;
		Items.PictureAddress.ContextMenu.Enabled = False;
	EndIf;
	
	ColorCache = New Structure;
	ColorCache.Insert("ErrorNoteText", StyleColors.ErrorNoteText);
	ColorCache.Insert("NotSelectedPictureTextColor", StyleColors.NotSelectedPictureTextColor);
	
	StyleColorsCache = New FixedStructure(ColorCache);
	
	ProductsLocalization.WhenCreatingOnServer_CertificatesOfItem_FormOfElement(ThisObject);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations


	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RefreshPresentation();
		
	If CurrentImage > 0 Then
		UpdateImageURL(Pictures[CurrentImage - 1].FileAddressInStorage,
								Pictures[CurrentImage - 1].AnErrorOccurredWhileReceivingImageData);

		If ValueIsFilled(Object.Ref) Then
			AttachedFile = Pictures[CurrentImage - 1].Ref;
			UpdateVisibilityOfImageCommands(AttachedFile);
		EndIf;
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ImagesMarkedForDeletion.Count() > 0 Then
		
		If Exit Then
			Cancel = True;
			WarningText = NStr("vi = 'Dữ liệu đã thay đổi. Tất cả thay đổi sẽ bị mất.';
								|ru = 'Данные были изменены. Все изменения будут потеряны.';
								|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
								|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
								|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
								|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
			
			Return;
		EndIf;
		
		SetDeleteMarkForAddedImages();
		
	EndIf;
	
EndProcedure

// Bypassing platform error 20020193
// The view is not displayed correctly.
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	Object.Description = Object.CertificatePresentation;
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ScopeOption = "SpecificProduct"
		And Not ValueIsFilled(Products) Then
		
		Cancel = True;
		
		MessageText = NStr("vi = 'Chưa điền vùng hiệu lực';
							|ru = 'Область действия не заполнена';
							|en = 'Scope is required'; fa = 'Scope is required';
							|it = 'Campo di attività non è compilato';
							|pl = 'Nie wypełniono zakresu działania';
							|tr = 'İşlem alanı doldurulmadı'");
		Common.MessageToUser(MessageText, , "Products");
		
	ElsIf ScopeOption = "ProductKind"
		And Not ValueIsFilled(ProductKind)Then
		
		Cancel = True;
		
		MessageText = NStr("vi = 'Chưa điền vùng hiệu lực';
							|ru = 'Область действия не заполнена';
							|en = 'Scope is required'; fa = 'Scope is required';
							|it = 'Campo di attività non è compilato';
							|pl = 'Nie wypełniono zakresu działania';
							|tr = 'İşlem alanı doldurulmadı'");
		Common.MessageToUser(MessageText, , "ProductKind");
		
	ElsIf ScopeOption = "GoodsList" Then
		RowFilter = New Structure("ProductKind", Catalogs.ItemKinds.EmptyRef());
		LinesNotFilledIn = Scope.FindRows(RowFilter);
		
		For Each LineNotFilledIn In LinesNotFilledIn Do
			Scope.Delete(LineNotFilledIn);
		EndDo;
		
		If Scope.Count()=0 Then
			Cancel = True;
			MessageText = NStr("vi = 'Chưa điền vùng hiệu lực';
								|ru = 'Область действия не заполнена';
								|en = 'Scope is required'; fa = 'Scope is required';
								|it = 'Campo di attività non è compilato';
								|pl = 'Nie wypełniono zakresu działania';
								|tr = 'İşlem alanı doldurulmadı'");
			Common.MessageToUser(MessageText, , "Scope");
		EndIf;
	EndIf;
	
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Entry in the register of the "Area of action of the Nomenclature Certificate".
	RecordSet = InformationRegisters.QualityCertificateApplicationAreas.CreateRecordSet();
	RecordSet.Filter.QualityCertificate.Set(Object.Ref);
	RecordSet.Read();
	
	ScopeTable = RecordSet.UnloadColumns();
	
	If ScopeOption = "SpecificProduct" Then
		NewScopeLine = ScopeTable.Add();
		NewScopeLine.ProductKind	= ProductKind;
		NewScopeLine.Products		= Products;
		NewScopeLine.Characteristic	= Characteristic;
		NewScopeLine.Series			= Series;
	ElsIf ScopeOption = "ProductKind" Then
		NewScopeLine = ScopeTable.Add();
		NewScopeLine.ProductKind = ProductKind;
	Else
		ScopeTable = Scope.Unload();
		ScopeTable.Columns.Add("QualityCertificate",
												New TypeDescription("CatalogRef.QualityCertificates"));
	EndIf;
	
	ScopeTable.FillValues(Object.Ref, "QualityCertificate");
	ScopeTable.GroupBy("QualityCertificate, ProductKind, Products, Characteristic, Series");
	
	RecordSet.Load(ScopeTable);
	RecordSet.Write();
	
	VTImagesMarkedForDeletion = ImagesMarkedForDeletion.Unload();
	VTImagesMarkedForDeletion.GroupBy("Ref", "Check");
	
	// Installation/Unchecking the deletion of attached files.
	For Each Image In VTImagesMarkedForDeletion Do
		SetMarkToDeleteImage(Image.Ref,Image.Check);
	EndDo;
	
	ImagesMarkedForDeletion.Clear();
	
	// Recording attached files.
	For Each Image In Pictures Do
		If ValueIsFilled(Image.BaseName) Then
			FileParameters = FilesOperations.FileAddingOptions();
			FileParameters.Author				= Users.AuthorizedUser();
			FileParameters.FilesOwner		= Object.Ref;
			FileParameters.BaseName		= Image.BaseName;
			FileParameters.ExtensionWithoutPoint	= Image.Extension;
			
			FilesOperations.AppendFile(FileParameters, Image.FileAddressInStorage);
		EndIf;
	EndDo;
	
	Pictures.Clear();
	
	UpdateImageTable();
	
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If CurrentImage > 0 Then
		UpdateImageURL(Pictures[CurrentImage - 1].FileAddressInStorage,
								Pictures[CurrentImage - 1].AnErrorOccurredWhileReceivingImageData);
	EndIf;
	
	Notify("Write_QualityCertificate", Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, "Write_File");
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "SelectingScopeOfProductCertificate" Then
		SelectionOfScope(Parameter);
	ElsIf EventName = "Write_File" Then
		ProcessFileEntries(EventName, Parameter, Source);
	EndIf;
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CertificateTypeOnChange(Item)
	
	RefreshPresentation(True);
	
EndProcedure

&AtClient
Procedure CertificateTypeAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	TypesArray = GenerateListOfTypes(Text);
	ChoiceData = New ValueList;
	ChoiceData.LoadValues(TypesArray);

EndProcedure

&AtClient
Procedure NumberOnChange(Item)
	RefreshPresentation(True);
EndProcedure

&AtClient
Procedure AuthorityIssuingDocumentOnChange(Item)
	RefreshPresentation();
EndProcedure

&AtClient
Procedure PermanentOnChange(Item)
	
	If Object.Permanent Then
		
		Object.ValidTo = Date(1, 1, 1);
		Items.ValidTo.Enabled = False;
		
	Else
		Items.ValidTo.Enabled = True;
	EndIf;
	
	RefreshPresentation();
	
EndProcedure

&AtClient
Procedure ScopeOptionOnChange(Item)
	
	ProcessChangeOfScopeOption();
	
EndProcedure

&AtClient
Procedure ProductKindOnChange(Item)
	
	ProductTypeWhenChangedOnServer();
	WhenChangingScope();
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	ProductsOnChangeServer();
	WhenChangingScope();
	
EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)
	Items.Series.Enabled = ValueIsFilled(Products) And (ValueIsFilled(Characteristic)
	Or Not ItemVariantsAreUsed) And SeriesAreUsed;
	WhenChangingScope();
EndProcedure

&AtClient
Procedure SeriesOnChange(Item)
	WhenChangingScope();
EndProcedure

&AtClient
Procedure SeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure();
	FormParameters.Insert("PickMode", "SelectSeries");
	FormParameters.Insert("ProductKind", ProductKind);
	FormParameters.Insert("Products", Products);
	FormParameters.Insert("Characteristic", Characteristic);
	FormParameters.Insert("ItemVariantsAreUsed", ItemVariantsAreUsed);
	
	Notification = New CallbackDescription("SeriesSelection_3Completion", ThisObject);
	
	OpenForm("Catalog.QualityCertificates.Form.ScopeChoiceFormBatch",
		FormParameters,,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SeriesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	ChoiceData.LoadValues(ListOfAutoSelectionSeries(Text, Products, Characteristic));
	
EndProcedure

&AtClient
Procedure PictureAddressClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(PictureAddress) Then
		ViewImage();
	Else
		
		If Not Items.ImageCommandBar.Enabled Then
			Return;
		EndIf;
		
		WhenAddingImage();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ValidToOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	RefreshPresentation();
	
	
EndProcedure

&AtClient
Procedure StartDateOfValidityPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If ValueIsFilled(Object.ValidTo)
		And Object.StartDateOfValidityPeriod > Object.ValidTo Then
		Object.StartDateOfValidityPeriod = Object.ValidTo;	
	EndIf;
	
	RefreshPresentation();
	
	
EndProcedure

&AtClient
Procedure HyperlinkToCertificateOfRACClick(Item)
	FileSystemClient.OpenURL(Object.RefToRACCertificate);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersScope

&AtClient
Procedure ScopeOnActivateRow(Item)
	SetCurScopeClient();
EndProcedure

&AtClient
Procedure ScopeProductKindOnChange(Item)
	
	CurrentData = Items.Scope.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurViewOfProducts = CurrentData.ProductKind;
	
	Items.Scope.CurrentData.SeriesAreUsed = SeriesAvailability_(CurViewOfProducts, True);
	Items.Scope.CurrentData.ItemVariantsAreUsed = False;
	
	WhenChangingScope();
	
EndProcedure

&AtClient
Procedure ScopeProductsOnChange(Item)		

	CurrentRow =  Items.Scope.CurrentData;
	
	If ValueIsFilled(CurrentRow.Products) Then
		ProductProperties_ = ProductScopeWhenChangedOnServer(CurrentRow.Products, CurrentRow.ProductKind);
		CurrentRow.ItemVariantsAreUsed = ProductProperties_.ItemVariantsAreUsed;
		
		If ProductProperties_.Property("ProductKind") Then
			CurrentActionArea.ProductKind = ProductProperties_.ProductKind;
			CurrentRow.ProductKind = ProductProperties_.ProductKind;	
			CurrentRow.SeriesAreUsed = ProductProperties_.SeriesAreUsed;	
		EndIf;		
	EndIf;
	
	WhenChangingScope();
	
EndProcedure

&AtClient
Procedure ScopeCharacteristicOnChange(Item)
	WhenChangingScope();
EndProcedure

&AtClient
Procedure ScopeSeriesOnChange(Item)
	WhenChangingScope();
EndProcedure

&AtClient
Procedure ScopeSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentRow = Items.Scope.CurrentData;
	StandardProcessing = False;
	FormParameters = New Structure();
	FormParameters.Insert("PickMode", "SelectSeries");
	FormParameters.Insert("ProductKind", CurrentRow.ProductKind);
	FormParameters.Insert("Products", CurrentRow.Products);
	FormParameters.Insert("Characteristic", CurrentRow.Characteristic);
	FormParameters.Insert("ItemVariantsAreUsed", CurrentRow.ItemVariantsAreUsed);
	
	Notification = New CallbackDescription("SeriesSelection_3Completion", ThisObject);
	
	OpenForm("Catalog.QualityCertificates.Form.ScopeChoiceFormBatch",
		FormParameters,,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ScopeSeriesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.Scope.CurrentData;
	
	ChoiceData = New ValueList;
	ChoiceData.LoadValues(ListOfAutoSelectionSeries(Text, CurrentData.Products, CurrentData.Characteristic));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure Pick(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("PickMode", "SelectionOfScope");
	Series = Undefined;

	OpenForm("Catalog.QualityCertificates.Form.ScopeChoiceFormBatch",FormParameters,,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ViewImage()
	
	ClearMessages();
	
	FileData = Pictures[CurrentImage-1];
	
	If ValueIsFilled(Object.Ref) Then
		If ValueIsFilled(AttachedFile) Then
			FilesOperationsClient.OpenFile(FilesOperationsClient.FileData(FileData.Ref,
																				UUID));
		Else
			MessageText = NStr("vi = 'Không có hình ảnh để xem';
								|ru = 'Отсутствует изображение для просмотра';
								|en = 'No preview image'; fa = 'No preview image';
								|it = 'Manca l''immagine per la visualizzazione';
								|pl = 'Brak obrazu do przeglądania';
								|tr = 'Önizleme görüntüsü yok'");
			CommonClient.MessageToUser(MessageText, ,"PictureAddress");
		EndIf;
	Else
		FileSystemClient.OpenFile(FileData.FileAddressInStorage, , FileData.FullName);
	EndIf;
	
EndProcedure

&AtClient
Procedure CopyScope(Command)
	
	If Items.Scope.CurrentData <> Undefined Then
		AttributesNames = "ProductKind, Products, SeriesAreUsed, Series, Characteristic, 
							|ItemVariantsAreUsed";
		StringStructure = New Structure(AttributesNames);
		FillPropertyValues(StringStructure, Items.Scope.CurrentData);
		Items.Scope.AddRow();
		FillPropertyValues(Items.Scope.CurrentData, StringStructure);
		FillPropertyValues(CurrentActionArea, StringStructure);
	EndIf;
	
EndProcedure

&AtClient
Procedure NextImage(Command)
	
	If CurrentImage < ImagesTotal Then
		CurrentImage = CurrentImage + 1;
		
		UpdateImageURL(Pictures[CurrentImage - 1].FileAddressInStorage,
				Pictures[CurrentImage - 1].AnErrorOccurredWhileReceivingImageData);
		
		UpdateImageCounter();
		
		If ValueIsFilled(Object.Ref) Then
			AttachedFile = Pictures[CurrentImage - 1].Ref;
			UpdateVisibilityOfImageCommands(AttachedFile);
		EndIf;

	EndIf;	
	
EndProcedure

&AtClient
Procedure PreviousImage(Command)
	
	If CurrentImage > 1 Then
		CurrentImage = CurrentImage - 1;
		
		UpdateImageURL(Pictures[CurrentImage - 1].FileAddressInStorage,
				Pictures[CurrentImage - 1].AnErrorOccurredWhileReceivingImageData);
				
		UpdateImageCounter();
		
		If ValueIsFilled(Object.Ref) Then
			AttachedFile = Pictures[CurrentImage - 1].Ref;
			UpdateVisibilityOfImageCommands(AttachedFile);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddImage(Command)
	
	WhenAddingImage();
	
EndProcedure

&AtClient
Procedure ClearImage(Command)
	
	If ImagesTotal > 0 Then
		
		If ValueIsFilled(Object.Ref) Then
			Modified = True;
			
			NewRow = ImagesMarkedForDeletion.Add();
			NewRow.Ref	= Pictures[CurrentImage - 1].Ref;
			NewRow.Check	= True;
		EndIf;
		
		Pictures.Delete(CurrentImage-1);
		
		ImagesTotal = ImagesTotal - 1;
		
		If CurrentImage>ImagesTotal Then
			CurrentImage = CurrentImage - 1;
		EndIf;
		
		If ImagesTotal = 0 Then
			UpdateImageURL("", False);
			
			AttachedFile = PredefinedValue("Catalog.QualityCertificates.EmptyRef");
		Else
			UpdateImageURL(Pictures[CurrentImage - 1].FileAddressInStorage,
									Pictures[CurrentImage - 1].AnErrorOccurredWhileReceivingImageData);
				
			If ValueIsFilled(Object.Ref) Then
				AttachedFile = Pictures[CurrentImage - 1].Ref;
			EndIf;
		EndIf;
		
		UpdateImageCounter();
		
		UpdateVisibilityOfImageCommands(AttachedFile);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddGoodsByPicking(Command)
	
	FormParameters = New Structure("UUID, KeepRecordsOfQualityCertificates",
									UUID, True);
	
	CallbackDescription = New CallbackDescription("AddGoodsByPickingCompletion", ThisObject);
	
	OpenForm("DataProcessor.GoodsSelectionByPicking.Form.Form",
				FormParameters,
				ThisObject,
				,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure UpdateStatusOfRAC(Command)
EndProcedure

&AtClient
Procedure ToDiscloseGroupOfRAC(Command)
EndProcedure

&AtClient
Procedure FillInAccordingToDataOfRAC(Command)
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScopeCharacteristic.Name);

	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.ProductKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("Enabled", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScopeCharacteristic.Name);

	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.ProductKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	SelectionGroupOr = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	SelectionGroupAnd2 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với tất cả đặc tính>';
													|ru = '<для всех характеристик>';
													|en = '<for all variants>'; fa = '<برای همه گونه‌ها>';
													|it = '<comune per tutte le caratteristiche>';
													|pl = '<dla wszystkich charakterystyk>';
													|tr = '<tüm varyantlar için>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScopeSeries.Name);

	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.ProductKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.SeriesAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
		
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra sê-ri>';
													|ru = '<серия не указывается>';
													|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
													|it = '<serie non è indicata>';
													|pl = '<seria nie jest określana>';
													|tr = '<parti belirtilmemektedir>'"));
	Item.Appearance.SetParameterValue("Enabled", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScopeSeries.Name);

	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.ProductKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.SeriesAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.Series");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với tất cả sê-ri>';
													|ru = '<для всех серий>';
													|en = '<for all batches>'; fa = '<برای همه بچ‌ها>';
													|it = '<comune per tutte le serie>';
													|pl = '<dla wszystkich serii>';
													|tr = '<tüm partiler için>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScopeProducts.Name);

	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.ProductKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với toàn bộ mặt hàng>';
													|ru = '<для всей номенклатуры>';
													|en = '<for all items>'; fa = '<برای همه اقلام>';
													|it = '<comune per tutti articoli>';
													|pl = '<dla całej nomenklatury>';
													|tr = '<tüm öğeler için>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScopeCharacteristic.Name);

	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.ProductKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Enabled", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScopeSeries.Name);

	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.ProductKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	SelectionGroupAnd = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Enabled", False);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValidTo.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Permanent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ValidTo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer(FillInScope_ = True)
	
	Items.ValidTo.Enabled = Not Object.Permanent;
	
	If FillInScope_ Then
		FillInScope(Object.Ref);
	EndIf;
	
	SetCurScope();
	
EndProcedure

&AtServer
Procedure UpdateImageTable()
	
	GenerateImageTable();
	
	If ImagesTotal > 0 Then
		AttachedFile = Pictures[CurrentImage - 1].Ref;
	EndIf;
	
EndProcedure

&AtClient
Procedure SeriesSelection_3Completion(SelectedSeries_, Var_Parameters) Export
	
	If ScopeOption = "SpecificProduct" Then
		Series = SelectedSeries_;
	Else
		Items.Scope.CurrentData.Series = SelectedSeries_;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAvailabilityAndPromptInputOfSeriesAndCharacteristicsOnClient()
	
	Items.Characteristic.Enabled = ItemVariantsAreUsed And ValueIsFilled(Products);
	Items.Series.Enabled = ValueIsFilled(Products) And (ValueIsFilled(Characteristic)
		Or Not ItemVariantsAreUsed) And SeriesAreUsed;
	
	If ItemVariantsAreUsed Then
		Items.Characteristic.InputHint = NStr("vi = '<đối với tất cả đặc tính>';
												|ru = '<для всех характеристик>';
												|en = '<for all variants>'; fa = '<برای همه گونه‌ها>';
												|it = '<comune per tutte le caratteristiche>';
												|pl = '<dla wszystkich charakterystyk>';
												|tr = '<tüm varyantlar için>'");
	Else
		Items.Characteristic.InputHint = NStr("vi = '<không sử dụng đặc tính>';
												|ru = '<характеристики не используются>';
												|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
												|it = '<le caratteristiche non vengono usate>';
												|pl = '<charakterystyki nie dotyczą>';
												|tr = '<varyantlar kullanılmamaktadır>'");
	EndIf;
	
	If SeriesAreUsed Then
		Items.Series.InputHint = NStr("vi = '<đối với tất cả sê-ri>';
										|ru = '<для всех серий>';
										|en = '<for all batches>'; fa = '<برای همه بچ‌ها>';
										|it = '<comune per tutte le serie>';
										|pl = '<dla wszystkich serii>';
										|tr = '<tüm partiler için>'");
	Else
		Items.Series.InputHint = NStr("vi = '<chưa chỉ ra sê-ri>';
										|ru = '<серия не указывается>';
										|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
										|it = '<serie non è indicata>';
										|pl = '<seria nie jest określana>';
										|tr = '<parti belirtilmemektedir>'");
	EndIf;	
	
EndProcedure


&AtServer
Procedure FillInScope(ProductCertificateReference)
	
	ScopeOption = "SpecificProduct";
	
	RecordSet = InformationRegisters.QualityCertificateApplicationAreas.CreateRecordSet();
	RecordSet.Filter.QualityCertificate.Set(ProductCertificateReference);
	RecordSet.Read();
	
	RegisterTable = RecordSet.Unload();
	
	NumberOfTableElements = RegisterTable.Count();
	
	If NumberOfTableElements = 1 Then
		
		ScopeString = RegisterTable[0];
		
		If ValueIsFilled(ScopeString.Products) Then
			ProductKind = ScopeString.ProductKind;
			Products    = ScopeString.Products;
			Characteristic  = ScopeString.Characteristic;
			Series           = ScopeString.Series;
			
			ProductsOnChangeServer();
		Else
			ScopeOption = "ProductKind";
			
			ProductKind = ScopeString.ProductKind;
			Products    = Catalogs.Products.EmptyRef();
			Characteristic  = Catalogs.ItemsCharacteristics.EmptyRef();
			Series           = Catalogs.ItemsBatches.EmptyRef();
			
			SeriesAreUsed          = Common.ObjectAttributeValue(ProductKind, "KeepAccountingByBatch");
			ItemVariantsAreUsed = ItemVariantsAreUsed(ProductKind);
		EndIf;
		
	ElsIf NumberOfTableElements > 0 Then
		
		ScopeOption = "GoodsList";
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Scope.ProductKind,
		|	Scope.Products,
		|	Scope.Characteristic,
		|	Scope.Series
		|INTO Scope
		|FROM
		|	&Scope AS Scope
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Scope.Products,
		|	Scope.ProductKind,
		|	Scope.Characteristic,
		|	Scope.Series,
		|	CASE
		|		WHEN Scope.Products.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
		|																		VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|																		VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ItemVariantsAreUsed,
		|	Scope.ProductKind.KeepAccountingByBatch AS SeriesAreUsed
		|FROM
		|	Scope AS Scope";
		
		Query.SetParameter("Scope", RegisterTable);
		
		Scope.Load(Query.Execute().Unload());
		
	EndIf;
	
	If ScopeOption = "SpecificProduct" Then
		Items.ScopePages.CurrentPage = Items.PageSpecificGoods;
	ElsIf ScopeOption = "ProductKind" Then
		Items.ScopePages.CurrentPage = Items.PageProductKind;
	Else
		Items.ScopePages.CurrentPage = Items.ManufacturedProductsListPage;
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshPresentation(ChangePresentation = False)
		
	CertificatePresentation = Object.CertificateType + " №" + Object.Number;
	If Object.Permanent Then
		DatePresentation = " " + NStr("vi = 'từ %StartDateOfValidityPeriod%';
										|ru = 'от %StartDateOfValidityPeriod%';
										|en = 'from %StartDateOfValidityPeriod%'; fa = 'from %StartDateOfValidityPeriod%';
										|it = 'dal %StartDateOfValidityPeriod%';
										|pl = 'z dn. %StartDateOfValidityPeriod%';
										|tr = '%StartDateOfValidityPeriod% tarihinden'");
	Else	
	    DatePresentation = " " + NStr("vi = 'từ %StartDateOfValidityPeriod% đến %ValidTo%';
										|ru = 'с %StartDateOfValidityPeriod% по %ValidTo%';
										|en = 'from %StartDateOfValidityPeriod% to %ValidTo%'; fa = 'from %StartDateOfValidityPeriod% to %ValidTo%';
										|it = 'dal %StartDateOfValidityPeriod% al %ValidTo%';
										|pl = 'z dn/ %StartDateOfValidityPeriod% do %ValidTo%';
										|tr = '%StartDateOfValidityPeriod%''dan %ValidTo% kadar'");
	EndIf;	
	
	DatePresentation = StrReplace(DatePresentation, "%StartDateOfValidityPeriod%",  Format(Object.StartDateOfValidityPeriod, "DLF=D"));
	DatePresentation = StrReplace(DatePresentation, "%ValidTo%",  Format(Object.ValidTo, "DLF=D"));
	
	If ValueIsFilled(Object.AuthorityIssuingDocument) Then
		PresentationIssued = NStr("vi = '. Nơi cấp: %AuthorityIssuingDocument%';
									|ru = '. Выдан: %AuthorityIssuingDocument%';
									|en = '. Issued by: %AuthorityIssuingDocument%'; fa = '. Issued by: %AuthorityIssuingDocument%';
									|it = '. Emesso: %AuthorityIssuingDocument%';
									|pl = '. Wydany: %AuthorityIssuingDocument%';
									|tr = '. Veren kurum: %AuthorityIssuingDocument%'");
		PresentationIssued = StrReplace(PresentationIssued, "%AuthorityIssuingDocument%", Object.AuthorityIssuingDocument);
	Else
		PresentationIssued = "";
	EndIf;
	
	Items.Presentation.ChoiceList.Clear();
	Items.Presentation.ChoiceList.Add(CertificatePresentation);	
	Items.Presentation.ChoiceList.Add(CertificatePresentation + DatePresentation);
	If ValueIsFilled(Object.AuthorityIssuingDocument) Then
		Items.Presentation.ChoiceList.Add(CertificatePresentation + DatePresentation + PresentationIssued);
	EndIf;

	If ChangePresentation Then
		Object.CertificatePresentation = CertificatePresentation;
	EndIf;
	
	
EndProcedure

&AtClient
Procedure ProcessChangeOfScopeOption()
	
	Modified = True;
	
	If CurrentActionArea.ScopeOption = "GoodsList" Then
		ChangeAreaOption = True;
		
		If Scope.Count() > 1 Then
			QueryText = NStr("vi = 'Khi thay đổi phương án vùng hiệu lực, danh sách sẽ bị xóa. Tiếp tục?';
							|ru = 'При смене варианта области действия список будет очищен. Продолжить?';
							|en = 'The list will be cleared when changing the scope. Continue?'; fa = 'The list will be cleared when changing the scope. Continue?';
							|it = 'Con la modifica della versione del campo di attività l''elenco sarà cancellato. Continuare?';
							|pl = 'Przy zmianie wariantu obszaru działania lista zostanie oczyszczona. Kontynuować?';
							|tr = 'İşlem alanı seçeneğinin değişimi sırasında liste temizlenecektir. Devam et?'");
			
			ShowQueryBox(
				New CallbackDescription("ScopeOptionWhenChangingAnswerToQuestion", ThisObject),
				QueryText,
				QuestionDialogMode.YesNo,
				,
				DialogReturnCode.No);
			Return;
		ElsIf Scope.Count() = 0 Then
			ChangeAreaOption = False;
		EndIf;
		
		ScopeOptionChangeScopeOption(ChangeAreaOption);
		
	ElsIf ScopeOption = "GoodsList" Then
		Scope.Clear();
		NewRow = Scope.Add();
		NewRow.ProductKind = ProductKind;
		NewRow.Products = Products;
		NewRow.Characteristic = Characteristic;
		NewRow.Series = Series;
		NewRow.ItemVariantsAreUsed = ItemVariantsAreUsed;
		NewRow.SeriesAreUsed = SeriesAreUsed;
		Items.Scope.CurrentRow = NewRow.GetID();
	EndIf;
	
	ScopeOptionOnChangeCompletion();
	
EndProcedure

&AtClient
Procedure ScopeOptionWhenChangingAnswerToQuestion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		ScopeOption = CurrentActionArea.ScopeOption;
		Return;
	EndIf;
	
	ScopeOptionChangeScopeOption(True);
	ScopeOptionOnChangeCompletion();
	
EndProcedure

&AtClient
Procedure ScopeOptionChangeScopeOption(Val ChangeAreaOption)
	
	If ChangeAreaOption Then
		CurrentRow = Items.Scope.CurrentData;
		ProductKind = CurrentRow.ProductKind; 
		Products = CurrentRow.Products;
		Characteristic = CurrentRow.Characteristic;
		Series = CurrentRow.Series;
		ItemVariantsAreUsed = CurrentRow.ItemVariantsAreUsed;
		SeriesAreUsed = CurrentRow.SeriesAreUsed;
		
		SetAvailabilityAndPromptInputOfSeriesAndCharacteristicsOnClient();
		
	EndIf;

EndProcedure

&AtClient
Procedure ScopeOptionOnChangeCompletion()
	
	If ScopeOption = "SpecificProduct" Then
		Items.ScopePages.CurrentPage = Items.PageSpecificGoods;
	ElsIf ScopeOption = "ProductKind" Then
		Items.ScopePages.CurrentPage = Items.PageProductKind;
	Else
		Items.ScopePages.CurrentPage = Items.ManufacturedProductsListPage;
	EndIf;
	
	SetCurScopeClient();

EndProcedure

&AtServer
Procedure ProductsOnChangeServer()
	
	If ValueIsFilled(Products) Then
		
		AttributesNames       = "ProductKind, UseVariants";
		ProductAttributes = Common.ObjectAttributesValues(Products, AttributesNames);
		ProductKind       = ProductAttributes.ProductKind;
		
		If ProductAttributes.UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems
			Or ProductAttributes.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind
			Or ProductAttributes.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
			
			Items.Characteristic.Enabled    = True;
			Items.Characteristic.InputHint = NStr("vi = '<đối với tất cả đặc tính>';
													|ru = '<для всех характеристик>';
													|en = '<for all variants>'; fa = '<برای همه گونه‌ها>';
													|it = '<comune per tutte le caratteristiche>';
													|pl = '<dla wszystkich charakterystyk>';
													|tr = '<tüm varyantlar için>'");
			
			ItemVariantsAreUsed = True;
			
		Else
			Items.Characteristic.Enabled    = False;
			Items.Characteristic.InputHint = NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'");
			
			ItemVariantsAreUsed = False;
		EndIf;
		
		SeriesAvailability_(ProductKind, False);
		
	Else
		Items.Characteristic.Enabled    = False;
		Items.Characteristic.InputHint = NStr("vi = '<không sử dụng đặc tính>';
												|ru = '<характеристики не используются>';
												|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
												|it = '<le caratteristiche non vengono usate>';
												|pl = '<charakterystyki nie dotyczą>';
												|tr = '<varyantlar kullanılmamaktadır>'");
		
		ItemVariantsAreUsed = False;
		
		Items.Series.Enabled    = False;
		Items.Series.InputHint = NStr("vi = '<chưa chỉ ra sê-ri>';
										|ru = '<серия не указывается>';
										|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
										|it = '<serie non è indicata>';
										|pl = '<seria nie jest określana>';
										|tr = '<parti belirtilmemektedir>'");
		
		SeriesAreUsed = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductTypeWhenChangedOnServer()
	
	CurViewOfProducts = Common.ObjectAttributeValue(Products, "ProductKind");
	
	If CurViewOfProducts <> ProductKind Then
		Products = Catalogs.Products.EmptyRef();
		ItemVariantsAreUsed = False;
		Items.Characteristic.Enabled = False;
		Items.Characteristic.InputHint = NStr("vi = '<không sử dụng đặc tính>';
												|ru = '<характеристики не используются>';
												|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
												|it = '<le caratteristiche non vengono usate>';
												|pl = '<charakterystyki nie dotyczą>';
												|tr = '<varyantlar kullanılmamaktadır>'");
	EndIf;
	
	SeriesAvailability_(ProductKind, False);
	
EndProcedure

&AtServer
Function SeriesAvailability_(CurViewOfProducts, IsList)
	
	If ValueIsFilled(CurViewOfProducts) Then
		KeepAccountingByBatch = Common.ObjectAttributeValue(CurViewOfProducts, "KeepAccountingByBatch");
	Else
		KeepAccountingByBatch = False;
	EndIf;
	
	If IsList Then
		Return KeepAccountingByBatch;
	EndIf;
	
	If KeepAccountingByBatch Then
		Items.Series.Enabled = ValueIsFilled(Products)
										And (ValueIsFilled(Characteristic)
											Or Not ItemVariantsAreUsed);
		Items.Series.InputHint = NStr("vi = '<đối với tất cả sê-ri>';
										|ru = '<для всех серий>';
										|en = '<for all batches>'; fa = '<برای همه بچ‌ها>';
										|it = '<comune per tutte le serie>';
										|pl = '<dla wszystkich serii>';
										|tr = '<tüm partiler için>'");
		SeriesAreUsed = True;
	Else
		Items.Series.Enabled = False;
		Items.Series.InputHint = NStr("vi = '<chưa chỉ ra sê-ri>';
										|ru = '<серия не указывается>';
										|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
										|it = '<serie non è indicata>';
										|pl = '<seria nie jest określana>';
										|tr = '<parti belirtilmemektedir>'");
		SeriesAreUsed = False;
	EndIf;
	
EndFunction

&AtServer
Function ProductScopeWhenChangedOnServer(Products, TypeOfProductInLine)
	
	ReturnStructure = New Structure;
	
	ProductAttributes = Common.ObjectAttributesValues(Products,
																		"UseVariants, ProductKind");
	UseVariants = ProductAttributes.UseVariants;
	ProductKind = ProductAttributes.ProductKind;
	
	If UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems 
		Or UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind
		Or UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
		ReturnStructure.Insert("ItemVariantsAreUsed",True);
	Else
		ReturnStructure.Insert("ItemVariantsAreUsed",False);
	EndIf;
	
	If ProductKind <> TypeOfProductInLine Then
		KeepAccountingByBatch = Common.ObjectAttributeValue(ProductKind, "KeepAccountingByBatch");
		ReturnStructure.Insert("ProductKind",ProductKind);
		ReturnStructure.Insert("SeriesAreUsed",KeepAccountingByBatch);
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Function ItemVariantsAreUsed(CurrentProducts)
	
	UseVariants = Common.ObjectAttributeValue(CurrentProducts, "UseVariants");
	
	If UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems
		Or UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind
		Or UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
		
		Return True;
		
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServer
Procedure SetCurScope()
	
	CurrentActionArea = New Structure;
	CurrentActionArea.Insert("ScopeOption", ScopeOption);
	
	If ScopeOption = "SpecificProduct"
		Or ScopeOption = "ProductKind" Then
		
		CurrentActionArea.Insert("ProductKind", ProductKind);
		CurrentActionArea.Insert("Products",    Products);
		CurrentActionArea.Insert("Characteristic",  Characteristic);
		CurrentActionArea.Insert("Series",           Series);
		
	Else
		If Items.Scope.CurrentRow = Undefined Then
			CurrentRow = Scope[0];
		Else
			CurrentRow = ?(Scope.FindByID(Items.Scope.CurrentRow) = Undefined,
								Scope[0],
								Scope.FindByID(Items.Scope.CurrentRow));
		EndIf;
		
		CurrentActionArea.Insert("ProductKind", CurrentRow.ProductKind);
		CurrentActionArea.Insert("Products",    CurrentRow.Products);
		CurrentActionArea.Insert("Characteristic",  CurrentRow.Characteristic);
		CurrentActionArea.Insert("Series",           CurrentRow.Series);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCurScopeClient()
	
	CurrentActionArea = New Structure;
	
	CurrentActionArea.Insert("ScopeOption", ScopeOption);
	
	If ScopeOption = "SpecificProduct"
		Or ScopeOption = "ProductKind" Then
		
		CurrentActionArea.Insert("ProductKind", ProductKind);
		CurrentActionArea.Insert("Products", Products);
		CurrentActionArea.Insert("Characteristic", Characteristic);
		CurrentActionArea.Insert("Series", Series);
		
	Else
		If Items.Scope.CurrentData = Undefined Then
			CurrentActionArea.Insert("ProductKind", Undefined);
			CurrentActionArea.Insert("Products", Undefined);
			CurrentActionArea.Insert("Characteristic", Undefined);
			CurrentActionArea.Insert("Series", Undefined);
		Else
			CurrentRow = Items.Scope.CurrentData;
			CurrentActionArea.Insert("ProductKind", CurrentRow.ProductKind);
			CurrentActionArea.Insert("Products", CurrentRow.Products);
			CurrentActionArea.Insert("Characteristic", CurrentRow.Characteristic);
			CurrentActionArea.Insert("Series", CurrentRow.Series);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingScope()
	
	If ScopeOption = "SpecificProduct"
		Or ScopeOption = "ProductKind" Then
		
		If CurrentActionArea.Characteristic <> Characteristic Then
			Series = PredefinedValue("Catalog.ItemsBatches.EmptyRef");
			
			SetCurScopeClient();
		ElsIf CurrentActionArea.Products <> Products Then
			Characteristic = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
			Series          = PredefinedValue("Catalog.ItemsBatches.EmptyRef");
			
			SetCurScopeClient();
		ElsIf CurrentActionArea.ProductKind <> ProductKind Then
			Products   = PredefinedValue("Catalog.Products.EmptyRef");
			Characteristic = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
			Series          = PredefinedValue("Catalog.ItemsBatches.EmptyRef");
			
			Items.Series.InputHint          = NStr("vi = '<chưa chỉ ra sê-ri>';
													|ru = '<серия не указывается>';
													|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
													|it = '<serie non è indicata>';
													|pl = '<seria nie jest określana>';
													|tr = '<parti belirtilmemektedir>'");
			Items.Characteristic.InputHint = NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'");
			
			SetCurScopeClient();
		EndIf;
		
	Else
		
		CurrentRow = Items.Scope.CurrentData;
		
		If CurrentActionArea.ProductKind <> CurrentRow.ProductKind Then
			CurrentRow.Products   = PredefinedValue("Catalog.Products.EmptyRef");
			CurrentRow.Characteristic = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
			CurrentRow.Series          = PredefinedValue("Catalog.ItemsBatches.EmptyRef");
			
			SetCurScopeClient();
		ElsIf CurrentActionArea.Products <> CurrentRow.Products Then
			CurrentRow.Characteristic = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
			CurrentRow.Series          = PredefinedValue("Catalog.ItemsBatches.EmptyRef");
			
			SetCurScopeClient();
		ElsIf CurrentActionArea.Characteristic <> CurrentRow.Characteristic Then
			CurrentRow.Series = PredefinedValue("Catalog.ItemsBatches.EmptyRef");
			
			SetCurScopeClient();
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Var_ChoiceParameters - Structure:
// 		* Area - String
&AtClient
Procedure SelectionOfScope(Var_ChoiceParameters)
	
	If Var_ChoiceParameters.Area = "ProductKind" Then
		
		NewScopeLine = Scope.Add();
		NewScopeLine.ProductKind = Var_ChoiceParameters.ProductKind;
		NewScopeLine.SeriesAreUsed = Var_ChoiceParameters.SeriesAreUsed;
		
	ElsIf Var_ChoiceParameters.Area = "Products" Then	
		
		NewScopeLine = Scope.Add();
		NewScopeLine.ProductKind = Var_ChoiceParameters.ProductKind;
		NewScopeLine.Products = Var_ChoiceParameters.Products;
		NewScopeLine.ItemVariantsAreUsed = Var_ChoiceParameters.ItemVariantsAreUsed;
		NewScopeLine.SeriesAreUsed = Var_ChoiceParameters.SeriesAreUsed;
		
	ElsIf Var_ChoiceParameters.Area = "Characteristic" Then	
		
		NewScopeLine = Scope.Add();
		NewScopeLine.ProductKind = Var_ChoiceParameters.ProductKind;
		NewScopeLine.Products = Var_ChoiceParameters.Products;
		NewScopeLine.Characteristic = Var_ChoiceParameters.Characteristic;
		NewScopeLine.ItemVariantsAreUsed = Var_ChoiceParameters.ItemVariantsAreUsed;
		NewScopeLine.SeriesAreUsed = Var_ChoiceParameters.SeriesAreUsed;

	ElsIf Var_ChoiceParameters.Area = "Series" Then
		
		NewScopeLine = Scope.Add();
		NewScopeLine.ProductKind = Var_ChoiceParameters.ProductKind;
		NewScopeLine.Products = Var_ChoiceParameters.Products;
		NewScopeLine.Characteristic = Var_ChoiceParameters.Characteristic;
		NewScopeLine.Series = Var_ChoiceParameters.Series;
		NewScopeLine.ItemVariantsAreUsed = Var_ChoiceParameters.ItemVariantsAreUsed;
		NewScopeLine.SeriesAreUsed = Var_ChoiceParameters.SeriesAreUsed;
		
	EndIf;	
	
EndProcedure	

&AtServerNoContext
Function GenerateListOfTypes(Text)
	
	Return Catalogs.QualityCertificates.AutomaticSelectionOfCertificateTypes(Text);
	
EndFunction

&AtClient
Procedure AddGoodsByPickingCompletion(AddressInTempStorage, AdditionalParameters) Export
	
	If ValueIsFilled(AddressInTempStorage) Then
		AddProductsBySelectionOnServer(AddressInTempStorage);
	EndIf;
	
EndProcedure

&AtServer
Procedure AddProductsBySelectionOnServer(AddressInTempStorage)
		
	GoodsTable = GetFromTempStorage(AddressInTempStorage);
		
	If GoodsTable.Count() = 0 Then
		Return;
	EndIf;
	
	Modified = True;
		
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic
	|INTO TableOfProducts
	|FROM
	|	&Table AS Table
	|WHERE
	|	Table.Products <> VALUE(Catalog.Products.EmptyRef)
	|
	|;
	|
	|SELECT
	|	TableOfProducts.Products.ProductKind  AS ProductKind,
	|	TableOfProducts.Products                  AS Products,
	|	TableOfProducts.Characteristic                AS Characteristic,
	|	CASE
	|		WHEN TableOfProducts.Products.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed,
	|	TableOfProducts.Products.ProductKind.KeepAccountingByBatch AS SeriesAreUsed
	|FROM
	|	TableOfProducts AS TableOfProducts";

	Query.SetParameter("Table", GoodsTable);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		NewRow = Scope.Add();
		FillPropertyValues(NewRow,Selection);

	EndDo;
		
EndProcedure

&AtServerNoContext
Function ListOfAutoSelectionSeries(Text, Products, Characteristic)
	
	Query = New Query;
	Query.SetParameter("Text", "%" + Text + "%");
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Warehouse", Catalogs.Warehouses.EmptyRef());
	Query.SetParameter("Premise", Catalogs.Warerooms.EmptyRef());
	Query.SetParameter("PackagingFactor", 1);
	Query.SetParameter("AllSeries", True);
	Query.SetParameter("RemainderSign", 1);
	Query.Text = DataProcessors.SelectBatchToDocuments.TextOfRequestToGenerateTableRegisterData("AllSeriesProducts")
		+ Common.QueryBatchSeparator() 
		+ "SELECT
		|	DataOfRegister.Series
		|FROM
		|	DataOfRegister AS DataOfRegister
		|WHERE
		|	DataOfRegister.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	AND (&AllSeries
		|	OR DataOfRegister.AvailableStock > 0)
		|	AND DataOfRegister.Series.Description LIKE &Text";
	
	Return Query.Execute().Unload().UnloadColumn("Series");
	
EndFunction

#Region WorkingWithImages

&AtClient
Procedure UpdateImageCounter()
	
	DecorationText = NStr("vi = '%CurrentImage% / %ImagesTotal%';
							|ru = '%CurrentImage% из %ImagesTotal%';
							|en = '%CurrentImage% from %ImagesTotal%'; fa = '%CurrentImage% from %ImagesTotal%';
							|it = '%CurrentImage% dal %ImagesTotal%';
							|pl = '%CurrentImage% z %ImagesTotal%';
							|tr = '%ImagesTotal%''dan %CurrentImage%'");
	DecorationText = StrReplace(DecorationText, "%CurrentImage%",	CurrentImage);
	DecorationText = StrReplace(DecorationText, "%ImagesTotal%",		ImagesTotal);
	
	ImageCounter = DecorationText;
	
EndProcedure

&AtServer
Function ImageDetails(FileRef)
	
	SetPrivilegedMode(True);
	Try
		AnErrorOccurredWhileReceivingImageData = False;
		
		FileData				= FilesOperations.FileData(FileRef, UUID);
		FileAddressInStorage	= FileData.RefToBinaryFileData;
	Except
		FileAddressInStorage = "";
	EndTry;
	
	FileAttributes = Common.ObjectAttributesValues(FileRef, "DeletionMark, FileOwner");
	SetPrivilegedMode(False);
	
	If IsBlankString(FileAddressInStorage) Then
		AnErrorOccurredWhileReceivingImageData = True;
	Else
		AnErrorOccurredWhileReceivingImageData = False;
	EndIf;
	
	ImageDetails = New Structure;
	ImageDetails.Insert("FileOwner", FileAttributes.FileOwner);
	ImageDetails.Insert("DeletionMark", FileAttributes.DeletionMark);
	ImageDetails.Insert("FileAddressInStorage", FileAddressInStorage);
	ImageDetails.Insert("AnErrorOccurredWhileReceivingImageData", AnErrorOccurredWhileReceivingImageData);
	
	Return ImageDetails;
	
EndFunction

&AtClient
Procedure UpdateImageURL(NewAddress, AnErrorOccurredWhileReceivingImageData)
	
	If AnErrorOccurredWhileReceivingImageData Then
		PictureAddress = "";
		
		Items.PictureAddress.NonselectedPictureText	= NStr("vi = 'Lỗi đọc tập tin hình ảnh';
																|ru = 'Ошибка при чтении файла изображения';
																|en = 'An error occurred when reading the image file'; fa = 'An error occurred when reading the image file';
																|it = 'Errore durante la lettura del file d''immagine';
																|pl = 'Błąd przy czytaniu pliku obrazu';
																|tr = 'Resim dosyası okunurken hata oluştu'");
		Items.PictureAddress.TextColor				= StyleColorsCache.ErrorNoteText;
	Else
		PictureAddress = NewAddress;
		
		Items.PictureAddress.NonselectedPictureText	= NStr("vi = 'Thêm hình ảnh';
																|ru = 'Добавить изображение';
																|en = 'Add image'; fa = 'افزودن تصویر';
																|it = 'Aggiungi l''immagine';
																|pl = 'Dodaj obraz';
																|tr = 'Resim ekle'");
		Items.PictureAddress.TextColor				= StyleColorsCache.NotSelectedPictureTextColor;
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateImageTable()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CatalogQualityCertificatesAttachedFiles.Ref,
	|	CatalogQualityCertificatesAttachedFiles.DeletionMark
	|FROM
	|	Catalog.QualityCertificatesAttachedFiles AS CatalogQualityCertificatesAttachedFiles
	|WHERE
	|	CatalogQualityCertificatesAttachedFiles.FileOwner = &FileOwner
	|	AND CatalogQualityCertificatesAttachedFiles.DeletionMark = FALSE
	|
	|ORDER BY
	|	CatalogQualityCertificatesAttachedFiles.CreationDate";
	
	Query.SetParameter("FileOwner",Object.Ref);
	
	AttachedFileSelection = Query.Execute().Select();
	
	While AttachedFileSelection.Next() Do
		FileAttributes = ImageDetails(AttachedFileSelection.Ref);
		
		NewImage = Pictures.Add();
		FillPropertyValues(NewImage, FileAttributes);
		
		NewImage.Ref = AttachedFileSelection.Ref;
	EndDo;
	
	ImagesTotal = Pictures.Count();
	
	If ImagesTotal > 0 Then
		If CurrentImage = 0 Then
			CurrentImage = 1;
		EndIf;
		
		DecorationText = NStr("vi = '%CurrentImage% / %ImagesTotal%';
								|ru = '%CurrentImage% из %ImagesTotal%';
								|en = '%CurrentImage% from %ImagesTotal%'; fa = '%CurrentImage% from %ImagesTotal%';
								|it = '%CurrentImage% dal %ImagesTotal%';
								|pl = '%CurrentImage% z %ImagesTotal%';
								|tr = '%ImagesTotal%''dan %CurrentImage%'");
		DecorationText = StrReplace(DecorationText, "%CurrentImage%",	CurrentImage);
		DecorationText = StrReplace(DecorationText, "%ImagesTotal%",		ImagesTotal);
		ImageCounter = DecorationText;
		
		DeletionMark = Pictures[CurrentImage - 1].DeletionMark;
		
		Items.PictureAddress.Enabled = Not DeletionMark;
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenAddingImage()
	
	ClearMessages();
	
	If ValueIsFilled(Object.Ref) Then
		LockFormDataForEdit();
		
		FilesOperationsClient.AddFiles(Object.Ref,
											UUID,
											ProductsClient.FilterImageFiles());
	Else
		AddImageNotAttached();
	EndIf;
	
EndProcedure

&AtClient
Procedure AddImageNotAttached()
	
	CallbackDescription = New CallbackDescription("AddImageNotAttachedCompletion", ThisObject);
	
	FileImportParameters = FileSystemClient.FileImportParameters();
	FileImportParameters.Dialog.Filter = ProductsClient.FilterImageFiles();
	
	FileSystemClient.ImportFile_(CallbackDescription, FileImportParameters);
	
EndProcedure

&AtClient
Procedure AddImageNotAttachedCompletion(FileThatWasPut, AdditionalParameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	FileNameStructure = CommonClientServer.ParseFullFileName(FileThatWasPut.Name);
	
	NewImage = Pictures.Insert(ImagesTotal);
	NewImage.FileAddressInStorage	= FileThatWasPut.Location;
	NewImage.FullName				= FileNameStructure.Name;
	NewImage.BaseName		= FileNameStructure.BaseName;
	NewImage.Extension				= CommonClientServer.ExtensionWithoutPoint(
												FileNameStructure.Extension);
	
	UpdateImageURL(FileThatWasPut.Location, False);
	
	ImagesTotal	= ImagesTotal + 1;
	CurrentImage	= ImagesTotal;
	
	UpdateImageCounter();
	
EndProcedure

&AtServer
Procedure SetMarkToDeleteImage(AttachedFileRef, Check)
	
	AttachedFileObject = AttachedFileRef.GetObject();
	AttachedFileObject.SetDeletionMark(Check);
	AttachedFileObject.Write();
	
EndProcedure

&AtServer
Procedure SetDeleteMarkForAddedImages()

	For Each Image In ImagesMarkedForDeletion Do
		If Not Image.Check Then
			SetMarkToDeleteImage(Image.Ref,True);	
		EndIf;	
	EndDo;
	
EndProcedure

&AtClient
Procedure ProcessFileEntries(EventName, Parameter, Source)
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	If TypeOf(Source) = Type("Array")
		And Source.Count() > 0 Then
		
		FileRef = Source[0];
		
	Else
		FileRef = Source;
	EndIf;
	
	If TypeOf(FileRef) = Type("CatalogRef.QualityCertificatesAttachedFiles") Then
		
		If CurrentImage > 0 Then
			
			RowFilter = New Structure("Ref", FileRef);
			ImageStrings = Pictures.FindRows(RowFilter);
			
			If ImageStrings.Count() > 0 Then
				UpdateCertificateImages();
				
				Return;
			EndIf;
			
		EndIf;
		
		FileAttributes = ImageDetails(FileRef);
		
		If FileAttributes.FileOwner <> Object.Ref Then
			Return;
		EndIf;
		
		Modified = True;
		
		NewImage = Pictures.Insert(ImagesTotal);
		FillPropertyValues(NewImage, FileAttributes);
		
		NewImage.Ref = FileRef;
		UpdateImageURL(FileAttributes.FileAddressInStorage,
								FileAttributes.AnErrorOccurredWhileReceivingImageData);
		
		ImagesTotal	= ImagesTotal + 1;
		CurrentImage	= ImagesTotal;
		
		UpdateImageCounter();
		
		AttachedFile = Pictures[CurrentImage - 1].Ref;
		
		UpdateVisibilityOfImageCommands(AttachedFile);
	Else
		UpdateCertificateImages();
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateCertificateImages()
	
	Modified = True;
	
	UpdateCertificateImagesServer();
	
	If ImagesTotal = 0 Then
		UpdateImageURL("", False);
	Else
		UpdateImageURL(Pictures[CurrentImage - 1].FileAddressInStorage,
								Pictures[CurrentImage - 1].AnErrorOccurredWhileReceivingImageData);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateCertificateImagesServer()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CertificateImages.Ref			AS Ref,
	|	CertificateImages.DeletionMark	AS DeletionMark,
	|	CertificateImages.CreationDate		AS CreationDate
	|INTO CertificateImages
	|FROM
	|	Catalog.QualityCertificatesAttachedFiles AS CertificateImages
	|
	|WHERE
	|	NOT CertificateImages.DeletionMark
	|	AND CertificateImages.FileOwner = &FileOwner
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ImagesMarkedForDeletion.Ref	AS Ref,
	|	ImagesMarkedForDeletion.Check	AS Check
	|INTO ImagesMarkedForDeletion
	|FROM
	|	&ImagesMarkedForDeletion AS ImagesMarkedForDeletion
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ImagesMarkedForDeletion.Ref	AS Ref,
	|	ImagesMarkedForDeletion.Check	AS Check
	|INTO ImagesToBeDeleted
	|FROM
	|	ImagesMarkedForDeletion AS ImagesMarkedForDeletion
	|		INNER JOIN Catalog.QualityCertificatesAttachedFiles AS CertificateImages
	|		ON ImagesMarkedForDeletion.Ref = CertificateImages.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CertificateImages.Ref			AS Ref,
	|	CertificateImages.DeletionMark	AS DeletionMark,
	|	CertificateImages.CreationDate		AS CreationDate
	|FROM
	|	CertificateImages AS CertificateImages
	|		LEFT JOIN ImagesToBeDeleted AS ImagesToBeDeleted
	|		ON CertificateImages.Ref = ImagesToBeDeleted.Ref
	|			AND ImagesToBeDeleted.Check
	|
	|WHERE
	|	ImagesToBeDeleted.Ref IS NULL
	|
	|ORDER BY
	|	CertificateImages.CreationDate";
	
	Query.SetParameter("FileOwner", Object.Ref);
	Query.SetParameter("ImagesMarkedForDeletion", ImagesMarkedForDeletion.Unload());
	
	QueryResult = Query.ExecuteBatchWithIntermediateData();
	
	AttachedFileSelection	= QueryResult[QueryResult.UBound()].Select();
	ImageNumber			= 0;
	NumberOfCurrentImage	= 0;
	
	Pictures.Clear();
	
	While AttachedFileSelection.Next() Do
		ImageNumber	= ImageNumber + 1;
		FileAttributes		= ImageDetails(AttachedFileSelection.Ref);
		
		NewImage = Pictures.Add();
		FillPropertyValues(NewImage, FileAttributes);
		
		NewImage.Ref = AttachedFileSelection.Ref;
		
		If NewImage.Ref = AttachedFile Then
			NumberOfCurrentImage = ImageNumber;
		EndIf;
	EndDo;
	
	ImagesTotal = Pictures.Count();
	
	If ImagesTotal > 0 Then
		CurrentImage = ?(NumberOfCurrentImage = 0, 1, NumberOfCurrentImage);
		AttachedFile = Pictures[CurrentImage - 1].Ref;
		
		DecorationText = NStr("vi = '%CurrentImage% / %ImagesTotal%';
								|ru = '%CurrentImage% из %ImagesTotal%';
								|en = '%CurrentImage% from %ImagesTotal%'; fa = '%CurrentImage% from %ImagesTotal%';
								|it = '%CurrentImage% del %ImagesTotal%';
								|pl = '%CurrentImage% z %ImagesTotal%';
								|tr = '%ImagesTotal%''dan %CurrentImage%'");
		DecorationText = StrReplace(DecorationText, "%CurrentImage%",	CurrentImage);
		DecorationText = StrReplace(DecorationText, "%ImagesTotal%",		ImagesTotal);
		
		ImageCounter = DecorationText;
		
		DeletionMark = Pictures[CurrentImage - 1].DeletionMark;
		
		Items.PictureAddress.Enabled = Not DeletionMark;
	Else
		CurrentImage = 0;
		AttachedFile = Undefined;
	EndIf;
	
	ImagesMarkedForDeletion.Load(QueryResult[QueryResult.UBound() - 1].Unload());
	
EndProcedure

&AtClient
Procedure UpdateVisibilityOfImageCommands(FileRef)
	
	If ValueIsFilled(FileRef) Then
		Result = FilesOperationsClient.FileData(FileRef);
		Extension = Result.Extension;
		If Extension <> "bpm" And Extension <> "dib" And Extension <> "emf" And Extension <> "gif" 
			And Extension <> "ico" And Extension <> "jpeg" And Extension <> "jpg" And Extension <> "png" 
			And Extension <> "svg" And Extension <> "tif" And Extension <> "wmf" Then
			Items.PrintSubmenu.Visible = False;
		Else
			Items.PrintSubmenu.Visible = True;
		EndIf; 
	Else
		Items.PrintSubmenu.Visible = True;
	EndIf;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion


#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_StartDateOfValidityPeriod" Then
		StartDateOfValidityPeriodOnChange(Items.StartDateOfValidityPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_ValidTo" Then
		ValidToOnChange(Items.ValidTo);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
