
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	AccessManagement.OnCreateAccessValueForm(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
		
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	

	ThereIsTheRightToEdit = Catalogs.ItemAccessGroups.HasUpdateRight(Object);
	
	ParametersOfAdditionalProperties = New Structure;
	ParametersOfAdditionalProperties.Insert("Object", Object);
	ParametersOfAdditionalProperties.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	ParametersOfAdditionalProperties.Insert("HideDeleted", False);
	PropertyManager.OnCreateAtServer(ThisObject, ParametersOfAdditionalProperties);
		
	If Not ThereIsTheRightToEdit 
		 And Not ValueIsFilled(Parameters.CopyingValue) Then
		Items.PagesProductProfile.PagesRepresentation = FormPagesRepresentation.None;
		Items.ItemDetailsPage.Visible = False;
		ProductProfile = Catalogs.Products.TableDocumentOfProductCard(Object, Undefined, False);
		If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
			Items.SubmenuGoTo.Visible = False;
		EndIf;
		UpdateCacheOfProductTypeDetails();
		OnCreateAtServerLocalization(Cancel, StandardProcessing);
		FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
		CustomizeFormAndUpdateCard();
		Return;
	EndIf;
	
	// Prohibit editing
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	UseProductCategories = GetFunctionalOption("UseProductCategories");
	UseMultiCountryAccounting = GetFunctionalOption("UseMultiCountryAccounting");
	IsBaseVersion = GetFunctionalOption("BaseVersion");
	
	If Parameters.ChoiceMode = True Then
		ForSelection = True;
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleKindsOfProducts") Then
		ArrayOfViews = Catalogs.ItemKinds.GetPresetProductTypes();
		Items.ProductKindSwitch.ChoiceList.LoadValues(ArrayOfViews);
		Items.ProductKindSwitchRequiredFields.ChoiceList.LoadValues(ArrayOfViews);
	EndIf;
	
	CubicMeterConversionFactor = 
		ProductsServer.CubicMeterConversionFactor(Constants.UnitOfMeasureForVolume.Get());
	
	If ValueIsFilled(Object.Ref) Then
		// Let 's set the availability
		// ... forms in general 
		ReadOnly = Not ThereIsTheRightToEdit;
		
		// ... label and price tag template fields
		Items.UseCustomPriceTagTemplate.ReadOnly   = Not AccessRight("Edit", Metadata.Catalogs.Products.Attributes.UseCustomPriceTagTemplate);
		Items.UseCustomTemplateLabels.ReadOnly = Not AccessRight("Edit", Metadata.Catalogs.Products.Attributes.UseCustomTemplateLabels);
		
		// ... fields of the image and its panel buttons
		YouHaveRightToEditImages    = AccessRight("Edit", Metadata.Catalogs.Products.Attributes.PicturesFile);
		Items.PicturesFile.Enabled = YouHaveRightToEditImages;
		Items.AddImage.Enabled = YouHaveRightToEditImages;
		Items.ChangeImage.Enabled = YouHaveRightToEditImages;
		Items.ClearImage.Enabled = YouHaveRightToEditImages;
		Items.SelectAnImageFromAttachedFiles.Visible = YouHaveRightToEditImages;
		
		// ... the description fields for the site and its selection buttons
		YouHaveRightToEditDescription = AccessRight("Edit", Metadata.Catalogs.Products.Attributes.DescriptionFileForWebsite);
		Items.DescriptionFileForWebsite.ReadOnly = Not YouHaveRightToEditDescription;
		
		// Edit mode
		Items.PagesProductProfile.CurrentPage = Items.ItemCardPage;
		ConfigureFormVisibility = "CollapseAllGroups";
		VisibilityModeShowHighPriorityOnly = False;
		
		HideRevealAllGroups(True);
		Items.GroupGroupingLeftRight.Visible=False;
		
		Items.ConfigureFormVisibility.ChoiceList.Delete(0);
		
		UpdateCacheOfProductTypeDetails();
		UpdateAdditionalAttributesItems(False);
		ConfigureAvailabilityOfBlockedBankingDetails();
		
	Else	
		
		StructureCreationParameters = New Structure;
		StructureCreationParameters.Insert("Description", "");
		
		For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
			If AdditionalLanguageIsUsed.Value = True Then
				StructureCreationParameters.Insert(StrTemplate("Description%1", AdditionalLanguageIsUsed.Key), "");
			EndIf;
		EndDo;
		
		StructureCreationParameters.Insert("DescriptionFull", "");
		StructureCreationParameters.Insert("CopySource", Parameters.CopyingValue);
		
		AdditionalParametersPassed = Undefined;
		If Parameters.Property("AdditionalParameters", AdditionalParametersPassed) And AdditionalParametersPassed <> Undefined Then
			CommonClientServer.SupplementStructure(StructureCreationParameters, AdditionalParametersPassed, True);
		EndIf;
			
		If Parameters.Property("FillingText")
			And Not IsBlankString(Parameters.FillingText) Then
			
			StructureCreationParameters.Description = Parameters.FillingText;
			
		EndIf;
		
		CreationParameters = New FixedStructure(StructureCreationParameters);
		
		If ValueIsFilled(Parameters.CopyingValue) Then
			// Copy mode
			Items.PagesProductProfile.CurrentPage = Items.ItemDetailsPage;
			ConfigureFormVisibility = "ShowAllItems";
			VisibilityModeShowHighPriorityOnly = False;
			
			HideRevealAllGroups(False);
			
			FillByCopyObject();
			
			ProductsKindBeforeChange = Object.ProductKind;
		Else
			// Creation mode
			Items.PagesProductProfile.CurrentPage = Items.ItemDetailsPage;
			ConfigureFormVisibility = "ShowMain";
			VisibilityModeShowHighPriorityOnly = True;
			
			HideRevealAllGroups(False);
		EndIf;
		
		FillInByCreationParameters();
		
		
		OnCreatReadAtServer();
		
	EndIf;
	
	OnCreateAtServerLocalization(Cancel, StandardProcessing);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	CustomizeFormAndUpdateCard();
	
	FormInitialized = True;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
		
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	

	StructureCreationParameters = New Structure();
	StructureCreationParameters.Insert("Description", Object.Description);
	StructureCreationParameters.Insert("DescriptionFull", Object.DescriptionFull);
	
	CreationParameters = New FixedStructure(StructureCreationParameters);
	
	ItemKitConfiguration = SetsServerCall.DefaultProductConfigurationOption(
										Object.Ref,
										Catalogs.ItemsCharacteristics.EmptyRef());
	
	UpdateImageURL(False);
	
	If Not Object.DescriptionFileForWebsite.IsEmpty() Then
		PathToTheDescriptionFile = String(Object.DescriptionFileForWebsite);
	EndIf;
	
	If FormInitialized Then
		UpdateCacheOfProductTypeDetails();
		UpdateAdditionalAttributesItems();
		CustomizeFormAndUpdateCard();
		ConfigureAvailabilityOfBlockedBankingDetails();
	EndIf;
	
	ProductsKindBeforeChange = Object.ProductKind;
	
	VATRateBeforeChange = Object.VATRate;
	StartDateOfVATRateApplication = Undefined;
	
	OnCreatReadAtServer();
	
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	ConvertCanBeSpecifiedInDocumentsAsString("Weight");
	ConvertCanBeSpecifiedInDocumentsAsString("VolumeM3");
	ConvertCanBeSpecifiedInDocumentsAsString("AreaTypeOfMeasurement");
	ConvertCanBeSpecifiedInDocumentsAsString("Length");
	
	If Object.UseCustomPriceTagTemplate Then 
		UseCustomPriceTagTemplate = 1;
	EndIf;
	
	If Object.UseCustomTemplateLabels Then 
		UseCustomTemplateLabels = 1;
	EndIf;
	
	If Object.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem Then
		PackagingUsage = "Individual_Set";
	Else
		PackagingUsage = "SharedSet";
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ThereIsTheRightToEdit Then
		OnOpenLocalization(Cancel);
		Return;
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	OnOpenLocalization(Cancel);
	FormEventsClient.OnOpen(ThisObject, Cancel);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	FormEvents.FillCheckProcessingAtServer(ThisObject, Cancel, CheckedAttributes);

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not CopySettingsAreSet
		Or Not UniquenessControlBeforeWritingIsCompleted Then
		PrepareDataForInteractivityBeforeRecording(Cancel);
	EndIf;
	
	If Cancel Then
		
		If ConfigureFormVisibility = "CollapseAllGroups" Then
			ConfigureFormVisibility = "ShowAllItems";
		EndIf;
		
		HideRevealAllGroups(False);
		
	EndIf;
	
	If Not Cancel
		And ValueIsFilled(Object.Ref)
		And Object.VATRate <> VATRateBeforeChange
		And Not ValueIsFilled(StartDateOfVATRateApplication) Then
		
		Cancel = True;
		
		TitleOfInputForm	= NStr("vi = 'Thuế suất GTGT áp dụng từ:';
									|ru = 'Ставка НДС применяется с:';
									|en = 'VAT rate is applied from:'; fa = 'VAT rate is applied from:';
									|it = 'Aliquota IVA applicabile con:';
									|pl = 'Stawka VAT jest stosowana od:';
									|tr = 'KDV oranı şunlar için uygulanıyor:'");
		CallbackDescription	= New CallbackDescription("SetStartDateOfVATRateApplicationCompletion", ThisObject);
		
		ShowInputDate(CallbackDescription, , TitleOfInputForm, DateFractions.Date);
		
	EndIf;
	
	If Not Cancel
		And ParametersForCopyingAdditionalData.Count() > 0
		And Not CopySettingsAreSet Then
		
		Cancel = True;
		
		FormParameters = New Structure();
		FormParameters.Insert("CopySource", CreationParameters.CopySource);
		FormParameters.Insert("ParametersForCopyingAdditionalData", ParametersForCopyingAdditionalData);
		
		OpenForm("Catalog.Products.Form.CopyAssociatedInformation",
			FormParameters,
			ThisObject,,,,
			New CallbackDescription("CopyAssociatedInformationCompletion", ThisObject),
			FormWindowOpeningMode.LockOwnerWindow
		);
		
	EndIf;
	
	If ValueIsFilled(AddressTemporaryStorageTableFound) Then
		
		Cancel = True;
		
		FormParameters = New Structure("AddressTemporaryStorageTableFound, ThisIsARecord", AddressTemporaryStorageTableFound,True);
		
		OpenForm("Catalog.Products.Form.CheckUnique",
			FormParameters,
			ThisObject,,,,
			New CallbackDescription("CheckForUniquenessCompletion", ThisObject),
			FormWindowOpeningMode.LockOwnerWindow
		);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PrepareDataForInteractivityBeforeRecording(Cancel)
	
	CheckRequiredBankingDetails(Cancel);
	
	If Not Cancel Then
		// We always call the uniqueness control, because it is necessary to check the uniqueness of the working name.
		AddressTemporaryStorageTableFound = CheckUniquenessOfGivenName(True, Cancel);
		ParametersForCopyingAdditionalData.Clear();
	EndIf;
	
	If Not Cancel
		And CreationParameters().Property("CopySource")
		And ValueIsFilled(CreationParameters().CopySource)
		And Not CopySettingsAreSet Then
		MatchesCopiedObjects = New Structure;
		
		If Object.UseVariants 
			= Enums.ItemVariantsUsageOptions.SpecialForItems Then
			MatchesCopiedObjects.Insert("Characteristics");
		EndIf;
		
		TransferOption =
			ProductsServer.OptionToTransferSettingsByCharacteristics(Object,
				CreationParameters().CopySource,
				MatchesCopiedObjects);
		If TransferOption = "TakeFromCorrespondence" Then
			ParametersForCopyingAdditionalData.Add("CopyCustomizedCharacteristics",
				NStr("vi = 'Sao chép đặc tính riêng';
					|ru = 'Копировать индивидуальные характеристики';
					|en = 'Copy specific variants'; fa = 'Copy specific variants';
					|it = 'Copiare le caratteristiche individuali';
					|pl = 'Kopiuj indywidualne cechy';
					|tr = 'Bireysel varyantları kopyala'"),
				True); 
		EndIf;
		
		If Object.UsePackages
			And Object.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem Then
			MatchesCopiedObjects.Insert("Packages");
		EndIf;
		
		TransferOption =
			ProductsServer.OptionToTransferSettingsByPackage(Object,
				CreationParameters().CopySource,
				MatchesCopiedObjects);
	
		If TransferOption = "TakeFromCorrespondence" Then
			ParametersForCopyingAdditionalData.Add("CopyCustomizedPackaging",
				NStr("vi = 'Sao chép bộ đóng gói riêng';
					|ru = 'Копировать индивидуальные упаковки';
					|en = 'Copy customized packaging units'; fa = 'Copy customized packaging units';
					|it = 'Copiare gli imballaggi individuali';
					|pl = 'Kopiuj indywidualne opakowania';
					|tr = 'Bireysel paketleme ünitelerini kopyala'"),
				True); 
		EndIf;
		
		If GetFunctionalOption("UseExcisableGoods")
			And ExcisableGoodsAccounting.ThisIsExcisableProduct(CreationParameters().CopySource)
			And ExcisableGoodsAccounting.ExcisableItemCategories(CreationParameters().CopySource).Count() > 0 Then
				MatchesCopiedObjects.Insert("ExciseCategories");
				UnitOfMeasurementSource = Common.ObjectAttributeValue(CreationParameters().CopySource, "UnitOfMeasure");
				
				If UnitOfMeasurementSource = Object.UnitOfMeasure Then
					ParametersForCopyingAdditionalData.Add("CopyExciseTaxCategories",
						NStr("vi = 'Sao chép các hàng hóa chịu thuế tiêu thụ đặc biệt';
							|ru = 'Копировать подакцизные категории';
							|en = 'Copy excisable categories'; fa = 'Copy excisable categories';
							|it = 'Copy excisable categories';
							|pl = 'Copy excisable categories';
							|tr = 'Tüketim vergisine tabi kategorileri kopyala'"),
						True);
				Else
					ParametersForCopyingAdditionalData.Add("CopyExciseCategoriesWithoutCoefficient",
						NStr("vi = 'Sao chép các hàng hóa chịu thuế tiêu thụ đặc biệt (không có hệ số)';
							|ru = 'Копировать подакцизные категории (без коэффициента)';
							|en = 'Copy excisable categories (without coefficient)'; fa = 'Copy excisable categories (without coefficient)';
							|it = 'Copy excisable categories (without coefficient)';
							|pl = 'Copy excisable categories (without coefficient)';
							|tr = 'Tüketim vergisine tabi kategorileri kopyala (katsayısız)'"),
						True);
				EndIf;
					
		EndIf;
		
		ProductsLocalization.ParametersForCopyingAdditionalData(
			Object,
			CreationParameters(),
			ParametersForCopyingAdditionalData,
			MatchesCopiedObjects);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If CallbackDescriptionOnClose <> Undefined Then
		If TypeOf(CallbackDescriptionOnClose.AdditionalParameters) = Type("Structure") Then
			CallbackDescriptionOnClose.AdditionalParameters.Insert("ProductsLink", Object.Ref);
		EndIf;
	EndIf; 
	
	BeforeCloseLocalization(Cancel, Exit, WarningText, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "InformationRegister.ProductsVATRates.Form.ProductsForm" Then
		If ValueSelected = True Then
			Read();
		Else
			CustomizeFormAndUpdateCard();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	WriteParameters.Insert("ThisIsNewProduct", Not ValueIsFilled(Object.Ref));
	
	CurrentObject.UseCustomTemplateLabels = Boolean(UseCustomTemplateLabels);
	CurrentObject.UseCustomPriceTagTemplate  = Boolean(UseCustomPriceTagTemplate);
	
	CurrentObject.AdditionalProperties.Insert("PrintNameGenerated");
	CurrentObject.AdditionalProperties.Insert("WorkingNameFormed");
	CurrentObject.AdditionalProperties.Insert("ChangingTypeOfProductHasBeenWorkedOut");
	CurrentObject.AdditionalProperties.Insert("WorkingNameVerified", True);
	
	If ValueIsFilled(StartDateOfVATRateApplication) Then
		CurrentObject.AdditionalProperties.Insert("StartDateOfVATRateApplication", StartDateOfVATRateApplication);
	EndIf;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
		
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	CopyParameter = ParametersForCopyingAdditionalData.FindByValue("CopyExciseTaxCategories");
	If CopyParameter <> Undefined
		And CopyParameter.Check Then
		
		ExcisableGoodsAccounting.CheckCopyDataOfExciseCategories(
			CreationParameters().CopySource, Cancel);
		
	EndIf;
	
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	FormEvents.OnWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	OnWriteAtServerLocalization(Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)


	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core	
	If ValueIsFilled(HTMLFileData)
		Or ValueIsFilled(ImageFileData) Then
		
		If ValueIsFilled(ImageFileData) Then
			
			ImageFileParameters = FilesOperations.FileAddingOptions();
			ImageFileParameters.Author				= Users.AuthorizedUser();
			ImageFileParameters.FilesOwner		= CurrentObject.Ref;
			ImageFileParameters.BaseName		= ImageFileData.BaseName;
			ImageFileParameters.ExtensionWithoutPoint	= ImageFileData.Extension;
			
			AttachedFile = FilesOperations.AppendFile(ImageFileParameters, PictureAddress);
			
			CurrentObject.PicturesFile = AttachedFile;
			
			ImageFileData = Undefined;
			
		EndIf;
		
		If ValueIsFilled(HTMLFileData) Then
			
			HTMLFileParameters = FilesOperations.FileAddingOptions();
			HTMLFileParameters.Author				= Users.AuthorizedUser();
			HTMLFileParameters.FilesOwner		= CurrentObject.Ref;
			HTMLFileParameters.BaseName		= HTMLFileData.BaseName;
			HTMLFileParameters.ExtensionWithoutPoint	= HTMLFileData.Extension;
			
			AttachedFile = FilesOperations.AppendFile(HTMLFileParameters, HTMLDescriptionAddress);
			
			CurrentObject.DescriptionFileForWebsite = AttachedFile;
			
			HTMLFileData = Undefined;
			
		EndIf;
		
		CopySource = ?(CreationParameters().Property("CopySource"),
								CreationParameters().CopySource,
								Undefined);
		
		CurrentObject.Write();
		
		Read();
		
		If ValueIsFilled(CopySource) Then
			StructureCreationParameters = New Structure(CreationParameters);
			StructureCreationParameters.Insert("CopySource", CopySource);
			
			CreationParameters = New FixedStructure(StructureCreationParameters);
		EndIf;
		
	EndIf;
	
	MatchesCopiedObjects = New Structure;
	
	CopyParameter = ParametersForCopyingAdditionalData.FindByValue("CopyCustomizedPackaging");
	If CopyParameter <> Undefined
		And CopyParameter.Check Then
		Catalogs.PackagesAndUnitsOfMeasure.CopyPackingHierarchy(Object.Ref,
																		CreationParameters().CopySource,
																		MatchesCopiedObjects);
	EndIf;
	
	CopyParameter = ParametersForCopyingAdditionalData.FindByValue("CopyCustomizedCharacteristics");
	If CopyParameter <> Undefined
		And CopyParameter.Check Then
		
		MatchingCharacteristics = New Map;
	
		Query = New Query;
		Query.Text = "
		|SELECT
		|	ItemsCharacteristics.Ref,
		|	ItemsCharacteristics.Description,
		|	ItemsCharacteristics.DescriptionFull,
		|	ItemsCharacteristics.AdditionalAttributes.(
		|		Ref,
		|		LineNumber,
		|		Property,
		|		Value,
		|		TextString
		|	)
		|FROM
		|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|WHERE
		|	ItemsCharacteristics.Owner = &Owner
		|	AND (NOT ItemsCharacteristics.DeletionMark)";
		
		Query.SetParameter("Owner", CreationParameters().CopySource);
		
		SelectionOfCharacteristics = Query.Execute().Select();
		
		While SelectionOfCharacteristics.Next() Do
			
			FeatureObject_ = Catalogs.ItemsCharacteristics.CreateItem();
			
			FeatureObject_.Description       = SelectionOfCharacteristics.Description;
			FeatureObject_.DescriptionFull = SelectionOfCharacteristics.DescriptionFull;
			
			SelectionAdditionalDetails = SelectionOfCharacteristics.AdditionalAttributes; // QueryResultSelection
			
			SelectionOfAdditionalBankingDetails = SelectionAdditionalDetails.Select();
			
			While SelectionOfAdditionalBankingDetails.Next() Do
				
				AdditionalBankingDetailsLine = FeatureObject_.AdditionalAttributes.Add();
				FillPropertyValues(AdditionalBankingDetailsLine,SelectionOfAdditionalBankingDetails);
				
			EndDo;
			
			FeatureObject_.Owner = Object.Ref;
			FeatureObject_.Write();
			
			MatchingCharacteristics.Insert(SelectionOfCharacteristics.Ref, FeatureObject_.Ref);
			
		EndDo;
		
		MatchesCopiedObjects.Insert("Characteristics", MatchingCharacteristics);
	EndIf;
	
	CopyParameter = ParametersForCopyingAdditionalData.FindByValue("CopyExciseTaxCategories");
	If CopyParameter <> Undefined
		And CopyParameter.Check Then
		
		ExcisableGoodsAccounting.CopyExciseCategories(Object.Ref,
			CreationParameters().CopySource, True);
		
	EndIf;
	
	CopyParameter = ParametersForCopyingAdditionalData.FindByValue("CopyExciseCategoriesWithoutCoefficient");
	If CopyParameter <> Undefined
		And CopyParameter.Check Then
		
		ExcisableGoodsAccounting.CopyExciseCategories(Object.Ref,
			CreationParameters().CopySource, False);
		
	EndIf;
		
	Items.TextOfDataOnUnrecordedExciseCategories.Visible = False;
	
	ProductsLocalization.CopyAdditionalData(Object,
		CreationParameters(),
		ParametersForCopyingAdditionalData,
		MatchesCopiedObjects);
	
	If Not Items.ItemCardPage.Enabled Then
		VisibilityModeShowHighPriorityOnly = False;
		ConfigureFormVisibility = "ShowAllItems";
		CustomizeFormAndUpdateCard();
		HideRevealAllGroups(False);
	Else
		CustomizeFormAndUpdateCard();
	EndIf;
	
	VATRateBeforeChange = Object.VATRate;
	StartDateOfVATRateApplication = Undefined;
	
	ObjectAttributesLock.LockAttributes(ThisObject);
	ConfigureAvailabilityOfBlockedBankingDetails();
	
	ParametersForCopyingAdditionalData.Clear();
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	AfterWriteAtServerLocalization(CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_Products", WriteParameters, Object.Ref);

	If ValueIsFilled(Barcode) Then
		
		QueryText =NStr("vi = 'Ghi nhận mã vạch?';
						|ru = 'Зарегистрировать штрихкод?';
						|en = 'Register barcode?'; fa = 'Register barcode?';
						|it = 'Registrare il codice a barre?';
						|pl = 'Zarejestrować kod kreskowy?';
						|tr = 'Barkodu kaydet?'");
		
		Notification = New CallbackDescription("ToRegisterBarcodeCompletion", ThisObject);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No, NStr("vi = 'Ghi nhận mã vạch';
																									|ru = 'Регистрация штрихкода';
																									|en = 'Barcode registration'; fa = 'Barcode registration';
																									|it = 'Registrazione del codice a barre';
																									|pl = 'Rejestracja kodu kreskowego';
																									|tr = 'Barkod kaydı'"));
	EndIf;
	
	FormEventsClient.AfterWrite(ThisObject, WriteParameters);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	AfterWriteLocalization(WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" Then
			If Items.Barcode.Visible
				And Items.Barcode.Enabled Then
				Barcode = EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter).Barcode;
			EndIf;
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "Write_ItemKinds" Then
		
		WhenWritingTypeOfProductItem();
	ElsIf EventName = "Write_ItemsBarcodes"
		And Parameter = Object.Ref Then
		
		CustomizeFormAndUpdateCard();
		
	ElsIf EventName = "Write_AnotherQualityGoods"
		And Parameter = Object.Ref Then
		
		ProcessRecordOfProductOfDifferentQuality();
		
	ElsIf EventName = "Write_ProductKitConfigurations"
		And Parameter.Property("KitOwner")
		And Parameter.KitOwner = Object.Ref Then
		
		If Object.UseVariants = PredefinedValue("Enum.ItemVariantsUsageOptions.DontUse")
			And Parameter.Property("Main")
			And Parameter.Main Then
			
			ItemKitConfiguration = Parameter.Kit;
			
		EndIf;
		
		CustomizeFormAndUpdateCard();
		
	ElsIf EventName = "Write_ItemsCharacteristics"
		And ValueIsFilled(Source) Then
		
		ProcessingAndRecording_ProductCharacteristics(Source);
		
	ElsIf EventName = "Entry_PackingProductList"
		And (Parameter = Object.Ref Or Parameter = Object.PackagingGroup) Then
		
		CustomizeFormAndUpdateCard();
		
	ElsIf EventName = "Write_QualityCertificate" Then
		NotificationProcessingRecord_Record_ItemCertificatesList(Parameter);
	ElsIf EventName = "IncludeDeleteInSegment"
		And Parameter = Object.Ref Then
		
		CustomizeFormAndUpdateCard();
		
	ElsIf EventName = "Write_TermsOfPurchaseFromVendors" Then
		CustomizeFormAndUpdateCard();
	ElsIf EventName = "SelectedPackagingForReports" Then
		
		If TypeOf(Parameter) = Type("Structure")
			And Parameter.Property("ZoomRatio") Then
			Object.UnitFactorForReports = Parameter.ZoomRatio;
		EndIf;
		
	ElsIf EventName = "Write_ProductsVATRates"
		And Source.Products = Object.Ref Then
		
		If TypeOf(Parameter) = Type("Structure")
			And Parameter.Property("ThisIsCurrentRate")
			And Parameter.ThisIsCurrentRate Then
			
			Read();
			
		Else
			CustomizeFormAndUpdateCard();
		EndIf
		
	ElsIf EventName = "Recording_ExciseCategoryOfItem"
		And Parameter.Products = Object.Ref Then
		CustomizeFormAndUpdateCard();
	ElsIf EventName = "HyperlinkGoToFormParametersAndQuestion"
		And Source = ThisObject Then
		
		HyperlinkGoToFormParametersAndQuestion(Parameter.TagName, Parameter.Hyperlink);
		
	EndIf;
	
	If EventName = "Write_File" Then
		ProcessFileEntries(EventName, Parameter, Source);
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure NotificationProcessingRecord_Record_ItemCertificatesList(Certificate)

	Query = New Query;
	Query.Text =
	"SELECT
	|	QualityCertificateApplicationAreas.QualityCertificate
	|FROM
	|	InformationRegister.QualityCertificateApplicationAreas AS QualityCertificateApplicationAreas
	|WHERE
	|	(QualityCertificateApplicationAreas.Products = &Products
	|			OR QualityCertificateApplicationAreas.ProductKind = &ProductKind
	|				AND QualityCertificateApplicationAreas.Products = VALUE(Catalog.Products.EmptyRef))
	|	AND NOT QualityCertificateApplicationAreas.QualityCertificate.DeletionMark
	|	AND QualityCertificateApplicationAreas.QualityCertificate.Status = VALUE(Enum.StatusesOfQualityCertificates.Valid_)
	|	AND QualityCertificateApplicationAreas.QualityCertificate = &QualityCertificate";
	
	Query.SetParameter("Products", Object.Ref);
	Query.SetParameter("ProductKind", Object.ProductKind);
	Query.SetParameter("QualityCertificate", Certificate);
	
	If Not Query.Execute().IsEmpty() Then
		CustomizeFormAndUpdateCard();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingAndRecording_ProductCharacteristics(Characteristic)

	Owner = Common.ObjectAttributeValue(Characteristic,"Owner");
	
	If Object.UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems 
		And Owner = Object.Ref 
		Or Object.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind 
		And Owner = Object.ProductKind
		Or Object.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind 
		And Owner = Object.ItemVariantsOwner Then
			CustomizeFormAndUpdateCard();
	EndIf;
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

&AtClient
Procedure CustomizeFormAndUpdateCardClient(Item)
	
	CustomizeFormAndUpdateCard();
	
EndProcedure

&AtClient
Procedure PagesProductProfileOnCurrentPageChange(Item, CurrentPage)
	
	ProcessChangeOfPagesOfItemCard(CurrentPage);
	
EndProcedure

&AtClient
Procedure PagesProductProfileOnCurrentPageChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Write();
	EndIf;
	
EndProcedure

&AtClient
Procedure ControlQualityOfReceivedGoodsOnChange(Item)
	
	CustomizeFormAndUpdateCard();
	If Not Object.ControlQualityOfReceivedGoods Then
		Object.TermOfQualityControl = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductKindOnChange(Item)
	
	ClearMessages();
	
	ProductItemViewWhenChangingFormSettings();
	
	FormEventsClient.WhenChangingElement(ThisObject, Item);

EndProcedure

#Region ConfiguringSFGISIntegration

&AtClient
Procedure TypeOfGISMTProductsOnChange(Item)


EndProcedure

&AtClient
Procedure FGISFlagOnChange(Item)


EndProcedure

&AtClient
Procedure TypeOfFGISProductsOnChange(Item)


EndProcedure

&AtClient
Procedure TypesOfFGISProductsURLProcessing(Item, FormattedStringURL, StandardProcessing)


EndProcedure

#EndRegion

&AtClient
Procedure UsePackagesOnChange(Item)
	
	If Not Object.UsePackages Then
		Object.PackagingGroup = Undefined;
	Else
		Object.PackagingGroup = ProductKindAttributes.PackagingGroup;
		If Object.PackagingGroup = PredefinedValue("Catalog.PackagingGroups.SpecialForItem") Then
			PackagingUsage = "Individual_Set";
		EndIf;
		Object.SuppliedInReusablePackage   = False;
		Object.ReusablePackageItems    = Undefined;
		Object.ReusablePackageVariant  = Undefined;
	EndIf;
	
	CustomizeFormAndUpdateCard();
	
	FormEventsClient.WhenChangingElement(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure UseOfPackagesIndividualSetOnChange(Item)
	Object.PackagingGroup = PredefinedValue("Catalog.PackagingGroups.SpecialForItem");
	CustomizeFormAndUpdateCard();
	FormEventsClient.WhenChangingElement(ThisObject, Item);
EndProcedure

&AtClient
Procedure UsingPackagesCommonSetOnChange(Item)
	Object.PackagingGroup = Undefined;
	CustomizeFormAndUpdateCard();
	FormEventsClient.WhenChangingElement(ThisObject, Item);
EndProcedure

&AtClient
Procedure PackagingGroupOnChange(Item)
	
	PackagingGroupOnChangeServer();
	
EndProcedure

&AtServer
Procedure PackagingGroupOnChangeServer()
	
	IndividualPackages = Object.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem;
	
	If Object.UsePackages
		And Not IndividualPackages  Then
		
		ObjectAttributes = Common.ObjectAttributesValues(
						Object.PackagingGroup,
						New Structure("UnitOfMeasure, UnitForReports, UnitFactorForReports"));
						NotDetailsToFillIn = "";
		If Not ValueIsFilled(ObjectAttributes.UnitForReports) Then
			NotDetailsToFillIn = "UnitForReports, UnitFactorForReports";
		EndIf;
		FillPropertyValues(Object, ObjectAttributes, , NotDetailsToFillIn);
	EndIf;
	
	CustomizeFormAndUpdateCard();
	
EndProcedure

&AtClient
Procedure PackagingGroupOpening(Item, StandardProcessing)
	
	If Object.PackagingGroup = PredefinedValue("Catalog.PackagingGroups.SpecialForItem") Then
		
		StandardProcessing = False;
		
		If Not ValueIsFilled(Object.Ref) Then
			
			If Not Write() Then
				
				MessageText = NStr("vi = 'Lỗi ghi lại phần tử!';
									|ru = 'Ошибка записи элемента!';
									|en = 'An error occurred when saving the item'; fa = 'An error occurred when saving the item';
									|it = 'Errore nella scrittura dell''elemento!';
									|pl = 'Błąd zapisu elementu!';
									|tr = 'Öğe kayıt hatası!'");
				ShowMessageBox(Undefined, MessageText);
				Return;
				
			EndIf;
			
		EndIf;
		
		Filter = New Structure;
		Filter.Insert("Owner", Object.Ref);
		
		OpenForm("Catalog.PackagesAndUnitsOfMeasure.ListForm", New Structure("Filter", Filter), ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UnitOfMeasureOnChange(Item)
	
	UnitOfMeasureOnChangeServer();
	FormEventsClient.WhenChangingElement(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ReusablePackageItemsOnChange(Item)
	
	ReusablePackageItemsOnChangeServer();
	
EndProcedure

&AtServer
Procedure ReusablePackageItemsOnChangeServer()
	
	CharacteristicsOfMultiTurnPackagingAreUsed = Catalogs.Products.ItemVariantsAreUsed(Object.ReusablePackageItems);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Object.ReusablePackageVariant);

	StringStructure = New Structure;
	StringStructure.Insert("Products", Object.ReusablePackageItems);
	StringStructure.Insert("Characteristic", Object.ReusablePackageVariant);
	StringStructure.Insert("ItemVariantsAreUsed", CharacteristicsOfMultiTurnPackagingAreUsed);
	
	BatchProcessingOfTablePartServer.ProcessTSString(StringStructure, StructureOfActions, Undefined);

	Object.ReusablePackageItems = StringStructure.Products;
	Object.ReusablePackageVariant = StringStructure.Characteristic;
	
	CharacteristicsOfMultiTurnPackagingAreUsed = StringStructure.ItemVariantsAreUsed;
	
	CustomizeFormAndUpdateCard();
	
EndProcedure

&AtClient
Procedure UnitForReportsStartChoice(Item, ChoiceData, StandardProcessing)
	If Object.UsePackages Then
		StandardProcessing = False;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("Products", Object.Ref);
		ParametersStructure.Insert("PackagingGroup", Object.PackagingGroup);
		ParametersStructure.Insert("StorageUnit", Object.UnitOfMeasure);
		ParametersStructure.Insert("UnitForReports", Object.UnitForReports);
		
		OpenForm("Catalog.PackagesAndUnitsOfMeasure.Form.SelectionFormOfUnitsForReports",
				ParametersStructure,
				Item, , , , ,
				FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure WeightUseOnChange(Item)
	HowToUseWhenChangingServer("Weight");
	FormEventsClient.WhenChangingElement(ThisObject, Item);
EndProcedure

&AtClient
Procedure VolumeUseOnChange(Item)
	HowToUseWhenChangingServer("VolumeM3");
EndProcedure

&AtClient
Procedure AreaUseOnChange(Item)
	HowToUseWhenChangingServer("AreaTypeOfMeasurement");
EndProcedure

&AtClient
Procedure LengthUseOnChange(Item)
	HowToUseWhenChangingServer("Length");
EndProcedure

&AtClient
Procedure YouCanSpecifyWeightInDocumentsOnChange(Item)
	MeasureCanBeSpecifiedInDocumentsWhenChanging("Weight");
EndProcedure

&AtClient
Procedure VolumeCanBeSpecifiedInDocumentsOnChange(Item)
	MeasureCanBeSpecifiedInDocumentsWhenChanging("VolumeM3");
EndProcedure

&AtClient
Procedure AreaCanBeSpecifiedInDocumentsOnChange(Item)
	MeasureCanBeSpecifiedInDocumentsWhenChanging("AreaTypeOfMeasurement");
EndProcedure

&AtClient
Procedure YouCanSpecifyLengthInDocumentsOnChange(Item)
	MeasureCanBeSpecifiedInDocumentsWhenChanging("Length");
EndProcedure

&AtClient
Procedure WeightUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("WeightUnitOfMeasure", StandardProcessing, "Weight");
EndProcedure

&AtClient
Procedure VolumeUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("VolumeUnitOfMeasure", StandardProcessing, "VolumeM3");
EndProcedure

&AtClient
Procedure AreaUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("AreaUnitOfMeasure", StandardProcessing, "AreaTypeOfMeasurement");
EndProcedure

&AtClient
Procedure LengthUnitOfMeasureClick(Item, StandardProcessing)
	UnitOfMeasurementClick("LengthUnitOfMeasure", StandardProcessing, "Length");
EndProcedure

&AtClient
Procedure UnitOfMeasurementClick(FieldName, StandardProcessing, MeasureName)
	
	StandardProcessing = False;
	
	NotificationParameters = New Structure("FieldName, MeasureName", FieldName, MeasureName);
	CallbackDescription  = New CallbackDescription("UnitOfMeasurementClickCompletion", ThisObject, NotificationParameters);
	
	NameOfMeasuredValueType = "Enum.TypesOfMeasuredValues." + MeasureName;
	MeasuredValueType     = PredefinedValue(NameOfMeasuredValueType);
	
	Filter          = New Structure("MeasuredValueType", MeasuredValueType);
	FormParameters = New Structure("Filter,CurrentRow", Filter, Object[FieldName]);
	
	OpenForm("Catalog.PackagesAndUnitsOfMeasure.ChoiceForm",
				FormParameters,
				ThisObject,
				,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure UnitOfMeasurementClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Modified = True;
		
		Object[AdditionalParameters.FieldName] = Result;
	EndIf;
	
	Measure = AdditionalParameters.MeasureName;
	MeasureProperties = MeasureProperties(Measure);
	
	ValuePresentationText = NStr("vi = 'Có thể chỉ định số lượng %UnitOfMeasure_% trong chứng từ';
								|ru = 'Можно указывать количество в %UnitOfMeasure_% в документах';
								|en = 'You can specify quantity in %UnitOfMeasure_% in the documents'; fa = 'You can specify quantity in %UnitOfMeasure_% in the documents';
								|it = 'È possibile indicare la quantità in %UnitOfMeasure_% nei documenti';
								|pl = 'Można określać ilość w %UnitOfMeasure_% w dokumentach';
								|tr = 'Belgelerde miktar %UnitOfMeasure_% olarak belirtilebilir'");
	ValuePresentationText = StrReplace(ValuePresentationText,
											"%UnitOfMeasure_%",
											String(Object[MeasureProperties.UnitOfMeasure]));
	
	Items[MeasureProperties.CanBeSpecifiedInDocuments].ChoiceList[1].Presentation = ValuePresentationText;
	
EndProcedure

&AtClient
Procedure PrincipalOnChange(Item)
	PrincipalWhenChangingOnServer();
EndProcedure

&AtClient
Procedure ManufacturerOnChange(Item)
	
	If UseProductCategories Then
		ManufacturerOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure OriginCountryOnChange(Item)
	
	FillInImportAndTraceabilityDetails();
	SetAvailabilityKeepRecordsOfCCDLocalization(Items.KeepRecordsByCCD, Object);
	SetAvailabilityTraceableItemLocalization(Items.TracedGoods, Object);
EndProcedure

&AtClient
Procedure UseACustomLabelTemplateWhenChanging(Item)
	
	Object.LabelsTemplate = PredefinedValue("Catalog.LabelAndPriceTagTemplates.EmptyRef");
	Object.UseCustomTemplateLabels = (UseCustomTemplateLabels = 1);
	
	CustomizeFormAndUpdateCard();
	
EndProcedure

&AtClient
Procedure UseAnIndividualPriceTagTemplateWhenChanging(Item)
	
	Object.PriceTagTemplate = PredefinedValue("Catalog.LabelAndPriceTagTemplates.EmptyRef");
	Object.UseCustomPriceTagTemplate = UseCustomPriceTagTemplate = 1;
	
	CustomizeFormAndUpdateCard();
	
EndProcedure

&AtClient
Procedure PictureAddressClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If IsBlankString(PictureAddress) Then
		LockFormDataForEdit();
		WhenAddingImage();
	Else
		MessageText = NStr("vi = 'Không có hình ảnh để xem';
							|ru = 'Отсутствует изображение для просмотра';
							|en = 'No preview image'; fa = 'No preview image';
							|it = 'Manca l''immagine per la visualizzazione';
							|pl = 'Brak obrazu do przeglądania';
							|tr = 'Önizleme görüntüsü yok'");
		
		ViewAttachedFile("PicturesFile", "PictureAddress", MessageText);
	EndIf;
		
EndProcedure

&AtClient
Procedure LongDescStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(Item.EditText,
																	ThisObject,
																	"Object.LongDesc",
																	NStr("vi = 'Thông tin bổ sung';
																		|ru = 'Дополнительная информация';
																		|en = 'Additional information'; fa = 'اطلاعات تکمیلی';
																		|it = 'Informazione supplementare';
																		|pl = 'Dodatkowa informacja';
																		|tr = 'Ek bilgi'"));
	
EndProcedure

&AtClient
Procedure DescriptionFileForWebsiteStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	WhenAddingDescriptionFile();
	
EndProcedure

&AtClient
Procedure DescriptionFileForWebsiteOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ClearMessages();
	
	MessageText = NStr("vi = 'Chưa chọn tệp mô tả';
						|ru = 'Файл описания не выбран';
						|en = 'Description file is not selected'; fa = 'Description file is not selected';
						|it = 'File di descrizione non selezionato';
						|pl = 'Plik opisu nie został wybrany';
						|tr = 'Dosya ayrıntıları seçilmedi'");
	
	ViewAttachedFile("DescriptionFileForWebsite", "PathToTheDescriptionFile", MessageText);
	
EndProcedure

&AtClient
Procedure DescriptionFileForWebsiteClearing(Item, StandardProcessing)
	
	PathToTheDescriptionFile			= "";
	Object.DescriptionFileForWebsite	= PredefinedValue("Catalog.ProductsAttachedFiles.EmptyRef");
	
EndProcedure

&AtClient
Function HyperlinkClickParameters(TagName, Hyperlink)
	
	HyperlinkClickParameters = New Structure("TagName,Hyperlink,FormName,URL,GroupName,FormParameters,FormWindowOpeningMode,ModifiabilityCheckMode,FormOwner");
	HyperlinkClickParameters.TagName = TagName;
	HyperlinkClickParameters.Hyperlink = Hyperlink;
	
	If TagName = "HyperlinkGoToItemWithSimilarProperties" Then
		
		FormParameters = New Structure("FilterNomenclatureByProperties", Object.Ref);
		
		HyperlinkClickParameters.FormName       = "Catalog.Products.Form.ListForm";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToOtherQualityProducts" Then
		
		FormParameters = New Structure("Products", Object.Ref);
		
		HyperlinkClickParameters.FormName       = "InformationRegister.AnotherQualityGoods.Form.ListForm";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToItemBarcodes" Then
		
		FormParameters = New Structure("Products", Object.Ref);
		
		HyperlinkClickParameters.FormName       = "InformationRegister.ItemsBarcodes.ListForm";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoConfigurationOptions"
		Or TagName = "HyperlinkGoSetComposition" Then
		
		FormParameters = New Structure("Products", Object.Ref);
		
		If Object.ItemsType = PredefinedValue("Enum.ItemsTypes.Set") Then
			
			If ValueIsFilled(ItemKitConfiguration) Then
				FormParameters = New Structure("Key", ItemKitConfiguration);
				
				HyperlinkClickParameters.FormName       = "Catalog.ProductKitConfigurations.Form.SetComposition";
				HyperlinkClickParameters.FormParameters = FormParameters;
			Else
				If Object.UseVariants = PredefinedValue("Enum.ItemVariantsUsageOptions.DontUse") Then
					Filter = New Structure;
					Filter.Insert("Owner", Object.Ref);
					Filter.Insert("Characteristic", PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
					FormParameters = New Structure("Filter", Filter);
					
					HyperlinkClickParameters.FormName       =  "Catalog.ProductKitConfigurations.Form.SetComposition";
					HyperlinkClickParameters.FormParameters = FormParameters;
				Else
					Filter = New Structure;
					Filter.Insert("Owner", Object.Ref);
					FormParameters = New Structure("Filter", Filter);
					
					HyperlinkClickParameters.FormName       =  "Catalog.ItemsCharacteristics.ListForm";
					HyperlinkClickParameters.FormParameters = FormParameters;
				EndIf;
			EndIf;
			
		Else
			Filter = New Structure;
			Filter.Insert("Owner", Object.Ref);
			FormParameters = New Structure("Filter", Filter);
			
			HyperlinkClickParameters.FormName       = "Catalog.ProductKitConfigurations.Form.ListForm";
			HyperlinkClickParameters.FormParameters = FormParameters;
		EndIf;
		
	ElsIf TagName = "HyperlinkGoToItemCharacteristics" Then
		
		Filter = New Structure;
		Filter.Insert("Owner", Object.Ref);
		FormParameters = New Structure("Filter", Filter);
		
		HyperlinkClickParameters.FormName       = "Catalog.ItemsCharacteristics.ListForm";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToItemPackaging" Then
		
		Filter = New Structure;
		Filter.Insert("Owner", Object.Ref);
		FormParameters = New Structure("Filter", Filter);
		
		HyperlinkClickParameters.FormName       = "Catalog.PackagesAndUnitsOfMeasure.ListForm";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkToGoPackingSet" Then
		
		Filter = New Structure;
		Filter.Insert("Owner", Object.PackagingGroup);
		FormParameters = New Structure("Filter", Filter);
		
		HyperlinkClickParameters.FormName       = "Catalog.PackagesAndUnitsOfMeasure.ListForm";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToPackageConsumptionForecasts" Then
		
		FormParameters = New Structure("Products", Object.Ref);
		
		HyperlinkClickParameters.FormName 	  = "InformationRegister.PackageConsumptionForecasts.Form.ListForm";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToItemPlacement" Then
		
		Filter = New Structure("Products", Object.Ref);
		FormParameters = New Structure("Filter", Filter);
		
		HyperlinkClickParameters.FormName       = "InformationRegister.PlaceProductsInStorageBins.Form.ListForm";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToItemCertificates" Then
		
		FormParameters = New Structure("Products", Object.Ref);
		
		HyperlinkClickParameters.FormName       = "Catalog.QualityCertificates.Form.ContextListForm";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToFiles" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("FileOwner",  Object.Ref);
		FormParameters.Insert("ReadOnly", ReadOnly);
		
		HyperlinkClickParameters.FormName       = "DataProcessor.FilesOperations.Form.AttachedFiles";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoDistributionOfSalesByLineOfBusiness" Then
		
		Filter = New Structure("Products", Object.Ref);
		FormParameters = New Structure("Filter", Filter);
		
		HyperlinkClickParameters.FormName 	  = "InformationRegister.SetUpAllocationByLinesOfBusiness.ListForm";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToJointSales" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Key",  Object.Ref);
		
		HyperlinkClickParameters.FormName       = "Catalog.Products.Form.JointSales";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToSegments" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Products", Object.Ref);
		
		HyperlinkClickParameters.FormName       = "InformationRegister.SegmentProducts.Form.ProductSegmentsParameter";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoSettingUpWaysToMeetYourNeeds" Then
		
		Filter = New Structure;
		Filter.Insert("Products", Object.Ref);
		FormParameters = New Structure;
		FormParameters.Insert("Filter",	Filter);
		FormParameters.Insert("Source",	"Products");
		
		HyperlinkClickParameters.FormName       = "DataProcessor.SettingOfProcurementStrategies.Form.Form";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToInventoryMaintenanceSettings" Then
		
		Filter = New Structure;
		Filter.Insert("Products", Object.Ref);
		FormParameters = New Structure;
		FormParameters.Insert("Filter",	Filter);
		FormParameters.Insert("Source",	"Products");
		
		HyperlinkClickParameters.FormName       = "DataProcessor.SetUpStockReplenishment.Form.Form";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToProduction" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Products",  Object.Ref);
		
		HyperlinkClickParameters.FormName       =  "CommonForm.ApplyProductsToManufacturing";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToCompanyPriceList" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Products",  Object.Ref);
		
		HyperlinkClickParameters.FormName       = "DataProcessor.PriceList.Form.Form";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToSupplierPriceLists" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Products",  Object.Ref);
		
		HyperlinkClickParameters.FormName       = "DataProcessor.VendorPriceLists.Form.Form";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoCompanyPriceChangeHistory" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Products", Object.Ref);

		If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
			HyperlinkClickParameters.FormName       = "InformationRegister.ItemsPrices25.Form.ListForm";
		Else
			HyperlinkClickParameters.FormName       = "InformationRegister.ItemsPrices.Form.ListForm";
		EndIf;
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoSupplierPriceChangeHistory" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Products", Object.Ref);
		
		HyperlinkClickParameters.FormName       = "InformationRegister.ItemsPricesOfVendor.Form.ListForm";
		HyperlinkClickParameters.FormParameters = FormParameters;
		
	ElsIf TagName = "HyperlinkGoToAgreements" Then
		
		PaddingValues = New Structure;
		PaddingValues.Insert("Partner",				Object.Principal);
		PaddingValues.Insert("Counterparty",				Object.Counterparty);
		PaddingValues.Insert("Status",					PredefinedValue("Enum.StatusesOfTermsOfPurchase.Valid"));
		PaddingValues.Insert("BusinessOperation",	PredefinedValue("Enum.BusinessTransactions.AgentServicesDelivery"));
		
		If Hyperlink = "AgreementsToChoose"
			Or Hyperlink = "ListOfAgreementsByProductName" Then
			
			PartnersForSelection = New Array;
			PartnersForSelection.Add(PredefinedValue("Catalog.Partners.EmptyRef"));
			PartnersForSelection.Add(Object.Principal);
			
			CounterpartiesForSelection = New Array;
			CounterpartiesForSelection.Add(PredefinedValue("Catalog.Counterparties.EmptyRef"));
			CounterpartiesForSelection.Add(Object.Counterparty);
			
			SelectionOfAgreements = New Structure;
			SelectionOfAgreements.Insert("Partner",					New FixedArray(PartnersForSelection));
			SelectionOfAgreements.Insert("Counterparty",				New FixedArray(CounterpartiesForSelection));
			SelectionOfAgreements.Insert("BusinessOperation",	PredefinedValue("Enum.BusinessTransactions.AgentServicesDelivery"));
			
			FilterCustom = New Structure;
			FilterCustom.Insert("State", PredefinedValue("Enum.StatesOfTermsOfPurchases.Valid"));
			
			ParametersForCreatingAgreement = New Structure;
			If Hyperlink = "AgreementsToChoose" Then
				PaddingValues.Insert("AgencyServiceProducts", Object.Ref);
				
				ParametersForCreatingAgreement.Insert("TheseServices", PaddingValues);
			EndIf;
			
			FormParameters = New Structure;
			FormParameters.Insert("Filter",							SelectionOfAgreements);
			FormParameters.Insert("QuickFilterStructure",			FilterCustom);
			FormParameters.Insert("EnableAgencyServiceSelection",	Hyperlink = "ListOfAgreementsByProductName");
			FormParameters.Insert("AgencyServiceProducts",		Object.Ref);
			FormParameters.Insert("AdditionalParameters",			ParametersForCreatingAgreement);
			
			HyperlinkClickParameters.FormName			= "Catalog.TermsOfPurchaseFromVendors.ListForm";
			HyperlinkClickParameters.FormParameters	= FormParameters;
			
		ElsIf Hyperlink = "AgreementsToCreate" Then
			
			FormParameters = New Structure;
			FormParameters.Insert("FillingValues",			PaddingValues);
			FormParameters.Insert("AgencyServiceProducts",	Object.Ref);
			
			HyperlinkClickParameters.FormName			= "Catalog.TermsOfPurchaseFromVendors.ObjectForm";
			HyperlinkClickParameters.FormParameters	= FormParameters;
			
		ElsIf Hyperlink = "ListOfAgreementsByCharacteristics" Then
			
			FormParameters = New Structure("Products", Object.Ref);
			
			HyperlinkClickParameters.FormName			= "Catalog.Products.Form.TermsOfPurchasesByItemVariants";
			HyperlinkClickParameters.FormParameters	= FormParameters;
			
		EndIf;
		
	ElsIf TagName = "HyperlinkGoToPreciousMaterials" Then
		
		HyperlinkClickParameters.GroupName = "HyperlinkGoToPreciousMaterials";
		
	ElsIf TagName = "HyperlinkToProductVATRates" Then
		
		FormParameters = New Structure("Products", Object.Ref);
		
		HyperlinkClickParameters.FormName = "InformationRegister.ProductsVATRates.Form.ProductsForm";
		HyperlinkClickParameters.FormParameters = FormParameters;
		HyperlinkClickParameters.FormWindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		
		HyperlinkClickParameters.GroupName = "HyperlinkGoToPreciousMaterials";
		
	ElsIf TagName = "HyperlinkGoExciseCategoriesOfItems" Then
		
		FormParameters = New Structure("Products", Object.Ref);
		
		HyperlinkClickParameters.FormName = "InformationRegister.ExcisableGoodsCategories.Form.ProductsForm";
		HyperlinkClickParameters.FormParameters = FormParameters;
		HyperlinkClickParameters.FormWindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		
	ElsIf TagName = "HyperlinkGoToCurrentExciseCategoryOfItem" Then
		
		ParametersOfCurrentExciseCategory = GetDataForSwitchingToCurrentExciseCategory();
		If ParametersOfCurrentExciseCategory = Undefined Then
			If Not IsBaseVersion Then
				FormParameters = New Structure("Products, CurrentPeriod", Object.Ref, True);
				HyperlinkClickParameters.FormName = "InformationRegister.ExcisableGoodsCategories.Form.ProductsForm";			
			Else
				FilterParameters = New Structure("Products", Object.Ref);
				FormParameters = New Structure("FillingValues", FilterParameters);
				HyperlinkClickParameters.FormName = "InformationRegister.ExcisableGoodsCategories.Form.RecordForm";
			EndIf;
		Else
			ParametersArray1 = New Array;
			ParametersArray1.Add(ParametersOfCurrentExciseCategory);
			RegisterRecordKey = New("InformationRegisterRecordKey.ExcisableGoodsCategories", ParametersArray1); 
			FormParameters = New Structure("Key", RegisterRecordKey);
			HyperlinkClickParameters.FormName = "InformationRegister.ExcisableGoodsCategories.Form.RecordForm";
		EndIf;
		
		HyperlinkClickParameters.FormParameters = FormParameters;
		HyperlinkClickParameters.FormWindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		
	EndIf;
	
	ProductsClientLocalization.HyperlinkClickParameters(ThisObject, HyperlinkClickParameters, TagName, Hyperlink);

	If HyperlinkClickParameters.FormWindowOpeningMode = Undefined Then
		HyperlinkClickParameters.FormWindowOpeningMode = FormWindowOpeningMode.Independent;
	EndIf;
	
	Return HyperlinkClickParameters;
	
EndFunction

&AtServer
Function GetDataForSwitchingToCurrentExciseCategory()
	
	TransmittedParameters = Undefined;
	TableOfCategories = ExcisableGoodsAccounting.GetHistoryOfItemCategories(Object.Ref,, CurrentSessionDate()); 
	If TableOfCategories.Count() = 1 Then
		TransmittedParameters = New Structure("Period, Products, Country", TableOfCategories[0].Period, Object.Ref, TableOfCategories[0].Country);
	EndIf;
	
	Return TransmittedParameters;
	
EndFunction

&AtServer
Function PopUpGroupPresentation(GroupName)
	
	If GroupName = "HyperlinkGoToPreciousMaterials" Then
		SpreadsheetDocument = TMCommonUse.TabularDocumentFromTableOfValues(
								Object.PreciousMetalsAndStones.Unload(),
								True,
								Metadata.Catalogs.Products.TabularSections.PreciousMetalsAndStones);
	Else
		ExceptionText = NStr("vi = 'Chưa xác định thao tác khi nhấp vào hyperlink khi người sử dụng không có quyền chỉnh sửa.';
							|ru = 'Не определено действие по гиперссылке для режима, когда у пользователя нет прав на редактирование.';
							|en = 'Hyperlink action is not identified for the mode when the user has no edit rights.'; fa = 'Hyperlink action is not identified for the mode when the user has no edit rights.';
							|it = 'Collegamento ipertestuale non definito per il regime in cui l''utente non ha diritti di modifica.';
							|pl = 'Działanie nie jest określono przy pomocy hiperłącza dla trybu, kiedy użytkownik niema praw do edytowania.';
							|tr = 'Kullanıcının düzenleme yetkisi olmadığında, mod için köprü eylemi tanımlanmamıştır.'");
		
		Raise ExceptionText;
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

&AtClient
Procedure HyperlinkGoToFormParametersAndQuestion(TagName, Hyperlink)
	
	ClearMessages();
	
	HyperlinkClickParameters = HyperlinkClickParameters(TagName, Hyperlink);
	
	If Not ValueIsFilled(Object.Ref)
		Or (Modified And HyperlinkClickParameters.ModifiabilityCheckMode <> "DontCheck") Then
		
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
		|Chỉ có thể chuyển đến thông tin bổ sung sau khi ghi lại phần tử.
		|Ghi lại phần tử?';
		|ru = 'Данные еще не записаны.
		|Переход к дополнительной информации возможен только после записи элемента.
		|Записать элемент?';
		|en = 'The data is not saved yet.
		|You can go to additional information only after the item is saved.
		|Save it?'; fa = 'The data is not saved yet.
		|You can go to additional information only after the item is saved.
		|Save it?';
		|it = 'I dati non sono ancora stati registrati.
		|Il passaggio all''informazione aggiuntiva è possibile solo dopo la registrazione dell''elemento.
		|Registrare l''elemento?';
		|pl = 'Dane nie zostały jeszcze zapisane.
		|Przejście do informacji dodatkowej jest możliwe tylko po zapisaniu elementu.
		|Zapisać element?';
		|tr = 'Veriler henüz kaydedilmedi.
		|Ek bilgilere geçiş, yalnızca öğenin kaydından sonra mümkündür.
		|Öğeyi kaydet?'");
		
		ShowQueryBox(New CallbackDescription("HyperlinkGoQuestionCompletion", ThisObject, HyperlinkClickParameters), QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	GoHyperlink(HyperlinkClickParameters);
	
EndProcedure

&AtClient
Procedure HyperlinkGoQuestionCompletion(QuestionResult, AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Try
		ItemRecorded = Write();
	Except
		Return;
	EndTry;
	
	If Not ItemRecorded Then
		Return;
	EndIf;
	
	HyperlinkClickParameters = HyperlinkClickParameters(AdditionalParameters.TagName,
																		AdditionalParameters.Hyperlink);
	GoHyperlink(HyperlinkClickParameters);
EndProcedure

&AtClient
Procedure HyperlinkGoNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	HyperlinkGoToFormParametersAndQuestion(Item.Name, FormattedStringURL);
	
EndProcedure

&AtClient
Procedure HyperlinkGoToCurrentExciseCategoryOfItem(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	HyperlinkGoToFormParametersAndQuestion(Item.Name, FormattedStringURL);
	
EndProcedure

&AtClient
Procedure HyperlinkGoExciseCategoryOfItem(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	HyperlinkGoToFormParametersAndQuestion(Item.Name, FormattedStringURL);
	
EndProcedure

&AtClient
Procedure GoHyperlink(HyperlinkClickParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Catalog.Products.Form.ItemForm.Command." + HyperlinkClickParameters.TagName);
	
	If HyperlinkClickParameters.FormName <> Undefined Then
		If HyperlinkClickParameters.FormName = "Catalog.Products.Form.ListForm" Then
			Notify("FilterBySimilarProperties_Products", Object.Ref, Object.Ref);
		EndIf;
		
		OpenForm(
			HyperlinkClickParameters.FormName,
			HyperlinkClickParameters.FormParameters,
			HyperlinkClickParameters.FormOwner,
			UUID,,,,
			HyperlinkClickParameters.FormWindowOpeningMode);
		
	ElsIf HyperlinkClickParameters.URL <> Undefined Then
		FileSystemClient.OpenURL(HyperlinkClickParameters.URL);
	ElsIf HyperlinkClickParameters.GroupName <> Undefined  Then
		If ThereIsTheRightToEdit Then
			Items.PagesProductProfile.CurrentPage = Items.ItemDetailsPage;
			ExpandCollapsibleGroup(HyperlinkClickParameters.GroupName);
			Items[HyperlinkClickParameters.GroupName].Show();
		Else
			SpreadsheetDocument = PopUpGroupPresentation(HyperlinkClickParameters.GroupName);
			SpreadsheetDocument.Show(Items[HyperlinkClickParameters.GroupName].Title);
		EndIf;
	Else
		StandardProcessing = True;
		ProductsClientLocalization.GoHyperlink(
			ThisObject,
			HyperlinkClickParameters,
			StandardProcessing);
		If StandardProcessing Then
			ExceptionText = NStr("vi = 'Chưa xác định thao tác khi nhấp vào hyperlink.';
								|ru = 'Не определено действие по гиперссылке.';
								|en = 'Hyperlink action is not identified.'; fa = 'Hyperlink action is not identified.';
								|it = 'Azione ipertestuale non definita.';
								|pl = 'Nie określono działania hiperłącza.';
								|tr = 'Köprü eylemi tanımlanmadı.'");
			Raise ExceptionText;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	RecalculateNeedForFormationOfNames(ThisObject);
	StructureCreationParameters = New Structure(CreationParameters);
	StructureCreationParameters.Description = Object.Description;
	CreationParameters = New FixedStructure(StructureCreationParameters);
	
EndProcedure

&AtClient
Procedure DescriptionFullOnChange(Item)
	
	RecalculateNeedForFormationOfNames(ThisObject);
	StructureCreationParameters = New Structure(CreationParameters);
	StructureCreationParameters.DescriptionFull = Object.DescriptionFull;
	CreationParameters = New FixedStructure(StructureCreationParameters);
	
EndProcedure

&AtClient
Procedure CheckForUniqueness(Command)
	ClearMessages();
	
	Cancel = False;
	AddressTemporaryStorageTableFound = CheckForUniquenessServer(Cancel); 
	
	If Not Cancel Then
		If ValueIsFilled(AddressTemporaryStorageTableFound) Then
			FormParameters = New Structure("AddressTemporaryStorageTableFound, Record", AddressTemporaryStorageTableFound, False);
			OpenForm("Catalog.Products.Form.CheckUnique",
				FormParameters,
				ThisObject,
				,
				,
				FormWindowOpeningMode.LockOwnerWindow,
				New CallbackDescription("CheckForUniquenessCompletion",
					ThisObject),
				FormWindowOpeningMode.LockOwnerWindow);
		Else
				ShowMessageBox(Undefined,NStr("vi = 'Mặt hàng là đơn trị';
												|ru = 'Позиция номенклатуры уникальна';
												|en = 'Items item is unique'; fa = 'Items item is unique';
												|it = 'La posizione dell''articolo è unica';
												|pl = 'Pozycja towarowa jest unikalna';
												|tr = 'Öğe konumu benzersizdir'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function CheckForUniquenessServer(Cancel)
	
	CheckRequiredBankingDetails(Cancel);
	
	If Not Cancel Then
		AddressTemporaryStorageTableFound = CheckUniquenessOfGivenName(False);
	Else
		AddressTemporaryStorageTableFound = "";
	EndIf;
	
	Return AddressTemporaryStorageTableFound;
	
EndFunction

// Parameters:
// 	Result - See ProductsClient.NewCompletionProcessingResult
// 	AdditionalParameters - Undefined - 
&AtClient
Procedure CheckForUniquenessCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Action = "SelectAnExisting" Then
		
		NotificationParameters = New Structure("ThisIsNewProduct", False);
		Notify("Write_Products",NotificationParameters,Result.Ref);
		
		If ForSelection Then
			NotifyChoice(Result.Ref);
		Else
			Modified = False;
			Close();
		EndIf;
		
	ElsIf Result.Action = "ContinueWrite" Then
		
		UniquenessControlBeforeWritingIsCompleted = True;
		
		Try
			ItemRecorded = Write();
		Except
			UniquenessControlBeforeWritingIsCompleted = False;
			Return;
		EndTry;
		
		If Not ItemRecorded Then
			UniquenessControlBeforeWritingIsCompleted = False;
			Return;
		EndIf;
		
		If ForSelection Then
			NotifyChoice(Object.Ref);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductProfileDetailProcessing(Item, Details, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Catalog.Products.ItemForm.Item.ProductProfile.DetailProcessing");
	
	If Not ValueIsFilled(Details) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If Not Items.GroupGroupingLeftRight.Visible Then
		Items.GroupGroupingLeftRight.Visible=True;
	EndIf;
	
	If TypeOf(Details) = Type("String")
		Or TypeOf(Details) = TypeOf(Details) = Type("FormattedString") Then
		TagName = Details;
		Hyperlink = "";
	ElsIf TypeOf(Details) = Type("Structure") Then
		TagName = Details.TagName;
		Hyperlink = Details.Hyperlink;
	Else
		ExceptionText = NStr("vi = 'Không hỗ trợ kiểu tham số diễn giải.';
							|ru = 'Неподдерживаемый тип параметры расшифровки.';
							|en = 'Drill-down parameter type is not supported.'; fa = 'Drill-down parameter type is not supported.';
							|it = 'Tipo del parametro di decodifica non supportato.';
							|pl = 'Nieobsługiwany typ parametry szczegółów płatności.';
							|tr = 'Desteklenmeyen tip detaylandırma parametreleri.'");
		Raise ExceptionText;
	EndIf;
		
	If JumpElementToLinkedList(Items, TagName) Then
		HyperlinkGoToFormParametersAndQuestion(TagName, Hyperlink);
	ElsIf Items.Find(TagName) <> Undefined Then
		If ThereIsTheRightToEdit Then
			Items.PagesProductProfile.CurrentPage = Items.ItemDetailsPage;
			
			ExpandCollapsibleGroup(TagName);
			SwitchingItemCardPages();
			
			CurrentItemSelection = TagName;
			AttachIdleHandler("SetActivityOfCurElement",0.0001,True);
		Else
			If Object.Property(TagName) Then
				If TypeOf(Object[TagName]) <> Type("String")
					And TypeOf(Object[TagName]) <> Type("Boolean")
					And ValueIsFilled(Object[TagName]) Then
					ShowValue(,Object[TagName]);
				EndIf;
			EndIf;
		EndIf;
	Else
		ExceptionText = NStr("vi = 'Kiểu tham số diễn giải chưa được xử lý.';
							|ru = 'Необрабатываемый тип параметр расшифровки.';
							|en = 'Cannot process drill-down parameter type.'; fa = 'Cannot process drill-down parameter type.';
							|it = 'Tipo del parametro di decodifica non elaborabile.';
							|pl = 'Nieprzetwarzany typ parametr szczegółów płatności.';
							|tr = 'İşlenmeyen tip detaylandırma parametresi'");
		Raise ExceptionText;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetActivityOfCurElement()
	CurrentItem = Items[CurrentItemSelection];
EndProcedure

&AtClient

&AtClient
Procedure ProductClassificationTypeCodeClearing(Item, StandardProcessing)
	
	Object.ProductClassificationTypeDescription = "";
	
EndProcedure

&AtClient
Procedure FEACNCodeOnChange(Item)
	
	FillInImportAndTraceabilityDetails();
	SetAvailabilityKeepRecordsOfCCDLocalization(Items.KeepRecordsByCCD, Object);
	SetAvailabilityTraceableItemLocalization(Items.TracedGoods, Object);

	CustomizeFormAndUpdateCard();
	
EndProcedure

&AtClient
Procedure FEACNCodeStartChoice(Item, ChoiceData, StandardProcessing)
	
	FormEventsClient.StartSelectingItem(ThisObject, Item, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure KeepRecordsByCCDOnChange(Item)
	
	SetAvailabilityKeepRecordsOfCCDLocalization(Items.KeepRecordsByCCD, Object);
	SetAvailabilityTraceableItemLocalization(Items.TracedGoods, Object);
EndProcedure

&AtClient
Procedure TracedGoodsOnChange(Item)
	
	TraceableItemOnChangeAtClient();
	
EndProcedure

&AtClient
Procedure TraceableItemOnChangeAtClient()
	
	ProductsClientServerLocalization.FillKeepRecordsOfCCD(Object);
	ProcessCommunicationLogicTraceableGoodsAndHSCodeLocalization();
	CustomizeFormAndUpdateCard();
	
EndProcedure

&AtClient
Procedure TransferProductBatchIDMaterialOnChange(Item)
	If Object.TransferProductBatchIDMaterial Then
		Object.TracedGoods = True;
	EndIf;
	
	TraceableItemOnChangeAtClient();
	Return;
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingElement(Item)
	FormEventsClient.WhenChangingElement(ThisObject, Item);
EndProcedure

&AtClient
Procedure BusinessActivityClassifierCodeOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure BusinessActivityClassifierCode2OnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure BusinessActivityClassifierCode2StartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure BusinessActivityClassifierCode2AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure RNCPCodeOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure RNCTEAPS2CodeOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure RNCTEAPS2CodeStartChoice(Item, ChoiceData, StandardProcessing)
	
	FormEventsClient.StartSelectingItem(ThisObject, Item, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ProductClassificationTypeCodeStartChoice(Item, ChoiceData, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure TRUCodeOnChange(Item)
	
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersItemMatches

&AtClient
Procedure ItemMatchesSelection(Item, RowSelected, Field, StandardProcessing)
	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInAPrintNameFromTemplate(Command)
	
	FillingResult = FillInANameFromTemplateServer("ForPrint");
	If FillingResult.HasErrors Then
		CommonClient.MessageToUser(FillingResult.ErrorText,, "Description", "Object");
	EndIf;
	NameTemplateForPrintingOfProductItem = TrimAll(GeneralPurposeTMServerCall.ObjectAttributeValue(Object.ProductKind, "NameTemplateForPrintingOfProductItem"));
	If NameTemplateForPrintingOfProductItem = "[Description]" 
		Or IsBlankString(NameTemplateForPrintingOfProductItem) Then 
		FillingResult = FillInMultilingualNameCompleteByName();
		If FillingResult.Property("ValuesInDifferentLanguages") Then 
			AdditionalParameters = New Structure("Object, AttributeName, Form", Object, "DescriptionFull", ThisObject);
			NationalLanguageSupportClient.AfterInputStringsInDifferentLanguages(FillingResult, AdditionalParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInAWorkNameFromTemplate(Command)
	
	FillingResult = FillInANameFromTemplateServer("Working");
	If FillingResult.HasErrors Then
		CommonClient.MessageToUser(FillingResult.ErrorText,, "Description", "Object");
	EndIf;
	
EndProcedure

&AtClient
Procedure ToRegisterBarcodeCompletion(Val Result, Val CommandParameter) Export
	
	If Result <> DialogReturnCode.Yes Then
		Barcode = Undefined;
		Return;
	EndIf;	
	
	If ValueIsFilled(Barcode) Then
		
		FillingValues = New Structure;
		FillingValues.Insert("Products", Object.Ref);
		FillingValues.Insert("Barcode", Barcode);
		FormParameters = New Structure("FillingValues", FillingValues);
		Barcode = Undefined;
		OpenForm("InformationRegister.ItemsBarcodes.RecordForm", FormParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddImage(Command)
	
	LockFormDataForEdit();
	WhenAddingImage();
	
EndProcedure

&AtClient
Procedure ClearImage(Command)
	
	Object.PicturesFile = PredefinedValue("Catalog.ProductsAttachedFiles.EmptyRef");
	ImageFileData = Undefined;
	
	UpdateImageURL(True);
	
EndProcedure

&AtClient
Procedure ViewImage(Command)
	
	ClearMessages();
	
	MessageText = NStr("vi = 'Không có hình ảnh để xem';
						|ru = 'Отсутствует изображение для просмотра';
						|en = 'No preview image'; fa = 'No preview image';
						|it = 'Manca l''immagine per la visualizzazione';
						|pl = 'Brak obrazu do przeglądania';
						|tr = 'Önizleme görüntüsü yok'");
	
	ViewAttachedFile("PicturesFile", "PictureAddress", MessageText);
	
EndProcedure

&AtClient
Procedure ChangeImage(Command)
	
	ClearMessages();
	
	If ValueIsFilled(Object.PicturesFile) Then
		FilesOperationsClient.OpenFileForm(Object.PicturesFile);
	Else
		MessageText = NStr("vi = 'Không có hình ảnh để chỉnh sửa';
							|ru = 'Отсутствует изображение для редактирования';
							|en = 'No image for editing'; fa = 'No image for editing';
							|it = 'Manca l''immagine per la modifica';
							|pl = 'Brak obrazu do edycji';
							|tr = 'Düzenlenecek görüntü yok'");
		
		CommonClient.MessageToUser(MessageText, , "PictureAddress");
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAnImageFromAttachedFiles(Command)
	
	StructureSelectionParameters	= New Structure("FileOwner, CloseOnChoice, ChoiceMode",
												Object.Ref, True, True);
	CallbackDescription			= New CallbackDescription("SelectAnImageFromAttachedFilesCompletion",
															ThisObject);
	
	OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles",
				StructureSelectionParameters,
				,
				,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure SelectAnImageFromAttachedFilesCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		Object.PicturesFile = Result;
		
		UpdateImageURL(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToCommand(Command)
	
	TagName = Command.Name;
	TagName = NameOfLinkedListTransitionElement(Items, TagName, False);
	
	HyperlinkGoToFormParametersAndQuestion(TagName, "");
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		
		OpenForm("Catalog.Products.Form.AttributeUnlocking",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockWholeInterface);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
		
		If Result.Find("UsePackages") <> Undefined Then
			Items.UseOfPackagesIndividualSet.ReadOnly = False;
			Items.UsingPackagesCommonSet.ReadOnly = False;
		EndIf;
		ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, Result);
		ProductsClientLocalization.AllowObjectAttributeEditCompletion(
			ThisObject, Result, AdditionalParameters);
	EndIf;
	
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

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
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



// DocumentRecognitionLibrary

&AtClient
Procedure SelectSimilarItemItem(Command)
	
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure PrincipalWhenChangingOnServer()
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Principal, Object.Counterparty);
	CustomizeFormAndUpdateCard();
EndProcedure

&AtServer
Procedure WhenWritingTypeOfProductItem()

	UpdateCacheOfProductTypeDetails();
	CustomizeFormAndUpdateCard();

EndProcedure

&AtServer
Procedure ProductTypeWhenChangedOnServer(FillingByCopySource = False)
	

	UpdateCacheOfProductTypeDetails();
	
	ObjectToFillIn = Object;
	ProductsLocalization.AddFormObject(ThisObject, ObjectToFillIn);

	Catalogs.Products.FillInDetailsForTypeOfProduct(ObjectToFillIn,
																	False,
																	False,
																	ProductsKindBeforeChange,
																	FillingByCopySource);
	
	ProductsLocalization.RestoreFormObject(ThisObject, ObjectToFillIn);

	ProductsKindBeforeChange = Object.ProductKind;
	
	If Not FillingByCopySource
		And ValueIsFilled(Object.ProductKind) Then
		
		If ValueIsFilled(ProductKindAttributes.WorkingNameTemplateOfProductItem) Then
			Object.Description = "";
			GenerateWorkName = True;
		ElsIf ValueIsFilled(CreationParameters().Description) Then
			// After switching back to the item type without a template, we return the original name.
			Object.Description = CreationParameters().Description;
		EndIf;
		
		If ValueIsFilled(ProductKindAttributes.NameTemplateForPrintingOfProductItem) Then
			Object.DescriptionFull = "";
			GeneratePrintName = True;
		ElsIf ValueIsFilled(CreationParameters().DescriptionFull) Then
			// After switching back to the item type without a template, we return the original name.
			Object.DescriptionFull = CreationParameters().DescriptionFull;
		EndIf;
		
		If Object.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem Then 
			PackagingUsage = "Individual_Set";
		EndIf;
		
	ElsIf FillingByCopySource
		And CreationParameters().Property("Quality")
		And ValueIsFilled(CreationParameters().Quality)
		And CreationParameters().Quality <> Enums.QualityLevels.New Then
		
		Object.Description = ?(GenerateWorkName, "", CreationParameters().Description);
		
		For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
			If AdditionalLanguageIsUsed.Value = True Then
				AttributeName = StrTemplate("Description%1", AdditionalLanguageIsUsed.Key);
				Object[AttributeName] = CreationParameters()[AttributeName];
			EndIf;
		EndDo;
		
		Object.DescriptionFull = ?(GeneratePrintName, "", CreationParameters().DescriptionFull);
		
	EndIf;
	
	UpdateAdditionalAttributesItems();
	
	IndividualPriceTagTemplateIsUsed  = ValueIsFilled(Object.PriceTagTemplate)
												And (Object.PriceTagTemplate <> ProductKindAttributes.PriceTagTemplate);
	IndividualLabelTemplateIsUsed = ValueIsFilled(Object.LabelsTemplate)
												And (Object.LabelsTemplate <> ProductKindAttributes.LabelsTemplate);
	
	Object.UseCustomPriceTagTemplate  = IndividualPriceTagTemplateIsUsed;
	Object.UseCustomTemplateLabels = IndividualLabelTemplateIsUsed;
	
	Object.PriceTagTemplate  = ?(IndividualPriceTagTemplateIsUsed, Object.PriceTagTemplate,
		Catalogs.LabelAndPriceTagTemplates.EmptyRef());
	Object.LabelsTemplate = ?(IndividualLabelTemplateIsUsed, Object.LabelsTemplate,
		Catalogs.LabelAndPriceTagTemplates.EmptyRef());
	
	SelectingPriceTagTemplateSettings = New Structure("AttributeName", "PriceTagTemplate");
	PriceTagTemplateSettings     = AttributeSettingTable.FindRows(SelectingPriceTagTemplateSettings);
	
	If PriceTagTemplateSettings.Count() > 0 Then
		
		If Not Object.UseCustomPriceTagTemplate
			And PriceTagTemplateSettings[0].RequiredToFill
			And Not ValueIsFilled(ProductKindAttributes.PriceTagTemplate) Then
			
			UseCustomPriceTagTemplate = 1;
			Object.UseCustomPriceTagTemplate = True;
			
		ElsIf Not Object.UseCustomPriceTagTemplate Then
			UseCustomPriceTagTemplate = 0;
		EndIf;
		
	EndIf;
	
	SelectingLabelTemplateSettings = New Structure("AttributeName", "LabelsTemplate");
	LabelTemplateSettings     = AttributeSettingTable.FindRows(SelectingLabelTemplateSettings);
	
	If LabelTemplateSettings.Count() > 0 Then
		
		If Not Object.UseCustomTemplateLabels
			And LabelTemplateSettings[0].RequiredToFill
			And Not ValueIsFilled(ProductKindAttributes.LabelsTemplate) Then
			
			UseCustomTemplateLabels = 1;
			Object.UseCustomTemplateLabels = True;
			
		ElsIf Not Object.UseCustomTemplateLabels Then
			UseCustomTemplateLabels = 0;
		EndIf;
		
	EndIf;
	
	Items.ProductKind.AutoMarkIncomplete = True;
	
	FormEvents.WhenChangingElement(ThisObject, "ProductKind");

EndProcedure

&AtServer
Procedure ProductItemViewWhenChangingFormSettings()
	
	ProductTypeWhenChangedOnServer();
	CustomizeFormAndUpdateCard();
	
EndProcedure

&AtServer
Procedure UpdateCacheOfProductTypeDetails()
	
	AttributesNames =
	"WorkingNameTemplateOfProductItem,
	|ProhibitEditingWorkingTitleOfItems,
	|NameTemplateForPrintingOfProductItem,
	|RestrictNameChangeToPrintItems,
	|BatchUsageSettings,
	|ContainsPreciousMetalsOrStones,
	|UseVariants,
	|KeepAccountingByBatch,
	|UseShelfLifeOnBatchRegistration,
	|PackagingGroup,
	|AccessGroup,
	|PropertiesSet,
	|ItemsType,
	|PriceTagTemplate,
	|LabelsTemplate";
	
	ProductKindAttributes = New FixedStructure(
		TMCommonUse.DefaultValuesForItemDetails(Object.ProductKind, AttributesNames));
	
	RecalculateNeedForFormationOfNames(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateNeedForFormationOfNames(Form)
	
	Form.GenerateWorkName =
		Form.ProductKindAttributes.ProhibitEditingWorkingTitleOfItems
		Or (Not ValueIsFilled(Form.Object.Description)
		And ValueIsFilled(Form.ProductKindAttributes.WorkingNameTemplateOfProductItem));
	Form.GeneratePrintName =
		Form.ProductKindAttributes.RestrictNameChangeToPrintItems
		Or (Not ValueIsFilled(Form.Object.DescriptionFull)
		And ValueIsFilled(Form.ProductKindAttributes.NameTemplateForPrintingOfProductItem));

EndProcedure

&AtClient
Procedure WhenAddingImage()
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		NotificationParameters	= New Structure("AttributeName", "ImageFileData");
		CallbackDescription	= New CallbackDescription("AddingFileIsNotAttachedEnding",
														ThisObject,
														NotificationParameters);
		
		FileImportParameters = FileSystemClient.FileImportParameters();
		FileImportParameters.Dialog.Filter = ProductsClient.FilterImageFiles();
		
		FileSystemClient.ImportFile_(CallbackDescription, FileImportParameters);
		
	Else
		
		NotificationParameters	= New Structure("SelectImage, SelectTheDescriptionFile", True, False);
		CallbackDescription	= New CallbackDescription("AddingFileCompletion",
														ThisObject,
														NotificationParameters);
		
		FilesOperationsClient.AddFiles(Object.Ref,
											UUID,
											ProductsClient.FilterImageFiles(),
											,
											CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenAddingDescriptionFile()
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		NotificationParameters	= New Structure("AttributeName", "HTMLFileData");
		CallbackDescription	= New CallbackDescription("AddingFileIsNotAttachedEnding",
														ThisObject,
														NotificationParameters);
		
		FileImportParameters = FileSystemClient.FileImportParameters();
		FileImportParameters.Dialog.Filter = NStr("vi = 'Tất cả tệp (*.*)|*.*';
													|ru = 'Все файлы (*.*)|*.*';
													|en = 'All files (*.*)|*.*'; fa = 'All files (*.*)|*.*';
													|it = 'Tutti i file (*.*)|*.*';
													|pl = 'Wszystkie pliki (*.*)|*.*';
													|tr = 'Tüm dosyalar (*.*)|*.*'");
		
		If ValueIsFilled(PathToTheDescriptionFile) Then
			FileImportParameters.Dialog.FullFileName = PathToTheDescriptionFile;
		EndIf;
		
		FileSystemClient.ImportFile_(CallbackDescription, FileImportParameters);
		
	Else
		
		NotificationParameters	= New Structure("SelectImage, SelectTheDescriptionFile", False, True);
		CallbackDescription	= New CallbackDescription("AddingFileCompletion",
														ThisObject,
														NotificationParameters);
		
		FilesOperationsClient.AddFiles(Object.Ref, UUID, , , CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddingFileIsNotAttachedEnding(FileThatWasPut, AdditionalParameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	ThisObject[AdditionalParameters.AttributeName] = DescriptionOfFileData();
	
	FileNameStructure = CommonClientServer.ParseFullFileName(FileThatWasPut.Name);
	
	ThisObject[AdditionalParameters.AttributeName].FullName		= FileNameStructure.Name;
	ThisObject[AdditionalParameters.AttributeName].BaseName	= FileNameStructure.BaseName;
	ThisObject[AdditionalParameters.AttributeName].Extension		= CommonClientServer.ExtensionWithoutPoint(
																		FileNameStructure.Extension);
	
	If AdditionalParameters.AttributeName = "ImageFileData" Then
		PictureAddress = FileThatWasPut.Location;
	ElsIf AdditionalParameters.AttributeName = "HTMLFileData" Then
		HTMLDescriptionAddress	= FileThatWasPut.Location;
		PathToTheDescriptionFile	= FileNameStructure.BaseName;
	EndIf;
	
EndProcedure

&AtClient
Procedure AddingFileCompletion(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles.Count() = 0 Then
		Return;
	EndIf;
	
	Modified = True;
	
	FileRef = SelectedFiles[0];
	
	If AdditionalParameters.SelectImage Then
		Object.PicturesFile = FileRef;
		
		UpdateImageURL(True);
	ElsIf AdditionalParameters.SelectTheDescriptionFile Then
		PathToTheDescriptionFile			= String(FileRef);
		Object.DescriptionFileForWebsite	= FileRef;
		
		CustomizeFormAndUpdateCard();
	EndIf;
	
EndProcedure

&AtClient
Procedure ViewAttachedFile(ObjectAttributeName, FormAttributeName, ErrorMessageText)
	
	If ValueIsFilled(Object.Ref) Then
		
		If ValueIsFilled(Object[ObjectAttributeName]) Then
			FilesOperationsClient.OpenFile(FilesOperationsClient.FileData(Object[ObjectAttributeName],
																				UUID));
		Else
			CommonClient.MessageToUser(ErrorMessageText, , FormAttributeName);
		EndIf;
		
	Else
		
		If ValueIsFilled(ThisObject[FormAttributeName]) Then
			
			If FormAttributeName = "PictureAddress" Then
				FileLocation1	= PictureAddress;
				FileName			= ?(TypeOf(ImageFileData) = Type("Structure"),
										ImageFileData.FullName,
										"");
			Else
				FileLocation1	= HTMLDescriptionAddress;
				FileName			= ?(TypeOf(HTMLFileData) = Type("Structure"),
										HTMLFileData.FullName,
										"");
			EndIf;
			FileSystemClient.OpenFile(FileLocation1, ,FileName);
			
		Else
			CommonClient.MessageToUser(ErrorMessageText, , FormAttributeName);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ManufacturerOnChangeServer()
		
	Object.Brand = Catalogs.Brands.GetDefaultBrand(Object.Manufacturer);
	
EndProcedure

&AtClient
Procedure KindOfAlcoholContainingProductsOnChange(Item)
	
	
EndProcedure

&AtClient
Procedure AlcoholContainingProductsOpenPackageOnChange(Item)
	
	
EndProcedure

&AtClient
Procedure CalculateVolumeInDecaliters(Command)

	
EndProcedure

#Region EventHandlersFormTablesPreciousMaterials

&AtClient
Procedure PreciousMetalsAndStonesPreciousMaterialOnChange(Item)
	
	
EndProcedure

&AtClient
Procedure Operations0StartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	

	Return;
	
EndProcedure

&AtClient
Procedure ItemParticipatesInActivityAtRateOfNDS0OnChange(Item)
	
	
	Return;

EndProcedure

#EndRegion

#EndRegion

#Region WorkingWithFilesAndImages

&AtServer
Procedure UpdateImageURL(CustomizeFormAndUpdateCard)
	
	If Object.PicturesFile.IsEmpty() Then
		PictureAddress = "";
		AnErrorOccurredWhileReceivingImageData = False;
	Else
		
		SetPrivilegedMode(True);
		Try
			PictureAddress = FilesOperations.FileData(Object.PicturesFile, UUID).RefToBinaryFileData;
		Except
			PictureAddress = "";
		EndTry;
		SetPrivilegedMode(False);
		
		If IsBlankString(PictureAddress) Then
			AnErrorOccurredWhileReceivingImageData = True;
		Else
			AnErrorOccurredWhileReceivingImageData = False;
		EndIf;
		
	EndIf;
	
	If CustomizeFormAndUpdateCard Then
		CustomizeFormAndUpdateCard();
	EndIf;
	
EndProcedure

&AtClient
Procedure CopyAssociatedInformationCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		CopySettingsAreSet = False;
		Return;
	EndIf;
	
	ParametersForCopyingAdditionalData = Result;
	
	UniquenessControlBeforeWritingIsCompleted = True;
	CopySettingsAreSet = True;
	
	Try
		ItemRecorded = Write();
	Except
		UniquenessControlBeforeWritingIsCompleted = False;
		CopySettingsAreSet = False;
		Return;
	EndTry;
	
	If Not ItemRecorded Then
		UniquenessControlBeforeWritingIsCompleted = False;
		CopySettingsAreSet = False;
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region SettingVisibilityOfGroupsAndElements

&AtServer
Procedure CustomizeFormAndUpdateCard()

	// The visibility settings of the form elements occur at the end of this procedure.
	// If the visibility of the form elements depends on the details of the form and these elements 
	// should not be displayed in the nomenclature card (the first tab of the form), then their visibility settings do not have 
	// to be entered into the procedure for the structure of the form elements (...). 
	// (But it is still better to try to enter without adding any parameters for uniformity).
		
	Items.ItemCardPage.Enabled = ValueIsFilled(Object.Ref);
	
	SetAvailabilityOfEditingNames(True);
	
	If Not ValueIsFilled(ProductKindAttributes.BatchUsageSettings) Then
		BatchUsageSettings = NStr("vi = 'Không sử dụng';
									|ru = 'Не используются';
									|en = 'Not used'; fa = 'استفاده نمی‌شود';
									|it = 'Non vengono utilizzati';
									|pl = 'Nie używa się';
									|tr = 'Kullanılmıyor'");
	Else
		BatchUsageSettings = String(ProductKindAttributes.BatchUsageSettings);
	EndIf;
	
	If Object.AccountingFeature = Enums.ItemAccountingFeatures.PerformedByCompanyOnAgencyBasis Then
		CompanyLinkType = New TypeDescription("CatalogRef.Companies");
		
		Items.Principal.TypeRestriction = CompanyLinkType;
	Else
		CounterpartiesLinkType = New TypeDescription("CatalogRef.Counterparties");
		LinkTypePartners = New TypeDescription("CatalogRef.Partners");
		
		Items.Principal.TypeRestriction  = LinkTypePartners;
		Items.Counterparty.TypeRestriction = CounterpartiesLinkType;
	EndIf;
	
	Items.TermOfQualityControl.Enabled = Object.ControlQualityOfReceivedGoods;
	Items.UnitOfMeasure.Enabled = (PackagingUsage = "Individual_Set"
											And Object.UsePackages)
											Or Not Object.UsePackages;
	
	AvailabilityOfLabelTemplates = UseCustomTemplateLabels = 1;
	Items.LabelsTemplate.Enabled = AvailabilityOfLabelTemplates;
	
	AvailabilityOfPriceTagTemplates = UseCustomPriceTagTemplate = 1;
	Items.PriceTagTemplate.Enabled = AvailabilityOfPriceTagTemplates;
	
	Items.AccessGroup.Enabled = ValueIsFilled(Object.Ref);
	
	If Items.Find("KeepRecordsByCCD") <> Undefined Then
		SetAvailabilityKeepRecordsOfCCDLocalization(Items.KeepRecordsByCCD, Object);
		SetAvailabilityTraceableItemLocalization(Items.TracedGoods, Object);
	EndIf;
	If Items.Find("TracedGoods") <> Undefined Then
		SetTraceableItemHintLocalization(Items.TracedGoods,
															Object.ItemsType,
															Enums.ItemsTypes.Work_5);
	EndIf;
	
	ObjectToFillIn = Object;
	ProductsLocalization.AddFormObject(ThisObject, ObjectToFillIn);

	BankingDetailsWithRedefinedMandatoryFields = Catalogs.Products.BankingDetailsWithRedefinedMandatoryFields(
															Object.ItemsType,
															ProductsLocalization.FeatureOfAccountingOrKeyTypesOfProducts(ThisObject),
															ObjectToFillIn);
	
	For Each KeyValue In BankingDetailsWithRedefinedMandatoryFields Do
		TagName = StrReplace(KeyValue.Key, ".", "");
		
		// It is configured according to the data of the 'Table of Set-up Requirements'.
		If TagName = "UnitOfMeasure" Then
			Continue;
		EndIf;
		
		Items[TagName].AutoMarkIncomplete	= KeyValue.Value;
		Items[TagName].MarkIncomplete		= KeyValue.Value;
	EndDo;
	
	VisibilityAndHeaderSettings = Catalogs.Products.VisibilityAndHeaderSettings(ObjectToFillIn, VisibilityModeShowHighPriorityOnly);

	ProductsLocalization.RestoreFormObject(ThisObject, ObjectToFillIn);
	
	VisibilityOfElements = VisibilityAndHeaderSettings.VisibilityOfElements;
	ItemsTitles = VisibilityAndHeaderSettings.ItemsTitles;
	
	ConfigureMeasureElements("Weight",	VisibilityOfElements, ItemsTitles, VisibilityModeShowHighPriorityOnly);
	ConfigureMeasureElements("VolumeM3",	VisibilityOfElements, ItemsTitles, VisibilityModeShowHighPriorityOnly);
	ConfigureMeasureElements("AreaTypeOfMeasurement",VisibilityOfElements, ItemsTitles, VisibilityModeShowHighPriorityOnly);
	ConfigureMeasureElements("Length",	VisibilityOfElements, ItemsTitles, VisibilityModeShowHighPriorityOnly);
	
	ConfigureClassifierFieldHint(Items.FEACNCode.Name, Object.FEACNCode);
	
	For Each VisibilityItem In VisibilityOfElements Do
		
		If Items.Find(VisibilityItem.Key) <> Undefined Then
			Items[VisibilityItem.Key].Visible = VisibilityItem.Value;
		EndIf;
		
		// Formation of visibility of the elements of the "Go" submenu
		CommandName = VisibilityItem.Key;
		If JumpElementToLinkedList(Items, CommandName) Then
			CommandName = NameOfLinkedListTransitionElement(Items, CommandName, True);
			
			If Items.Find(CommandName) <> Undefined Then
				Items[CommandName].Visible = VisibilityItem.Value;
			EndIf;
		EndIf;
		
	EndDo;
	
	For Each ItemHeader In ItemsTitles Do
		
		TagName = ItemHeader.Key;
		
		ItemTitle = Catalogs.Products.HyperlinkHeader(ItemHeader);
		
		Control = Items.Find(TagName);
		
		If Control <> Undefined
			And TypeOf(Control) <> Type("FormGroup") Then
			Control.Title = ItemTitle;
		EndIf;
		
		// Formation of the headings of the elements of the "Go" submenu
		If JumpElementToLinkedList(Items, TagName) Then
			
			CommandName = NameOfLinkedListTransitionElement(Items, TagName, True);
			
			If Items.Find(CommandName) <> Undefined Then
				
				LineException = NStr("vi = 'Danh sách';
									|ru = 'Список';
									|en = 'List'; fa = 'فهرست';
									|it = 'Elenco';
									|pl = 'Lista';
									|tr = 'Liste'");
				BeginningOfTheLine     = StrFind(ItemTitle, "(") - 1;
				
				If StrFind(ItemTitle, LineException) = 0
					And BeginningOfTheLine > 0 Then
					
					Items[CommandName].Title = TrimAll(Left(ItemTitle, BeginningOfTheLine));
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If AnErrorOccurredWhileReceivingImageData Then
		Items.PicturesFile.NonselectedPictureText	= NStr("vi = 'Lỗi đọc tập tin hình ảnh';
															|ru = 'Ошибка при чтении файла изображения';
															|en = 'An error occurred when reading the image file'; fa = 'An error occurred when reading the image file';
															|it = 'Errore durante la lettura del file d''immagine';
															|pl = 'Błąd przy czytaniu pliku obrazu';
															|tr = 'Resim dosyası okunurken hata oluştu'");
		Items.PicturesFile.TextColor				= StyleColors.ErrorNoteText;
	Else
		Items.PicturesFile.NonselectedPictureText	= NStr("vi = 'Thêm hình ảnh';
															|ru = 'Добавить изображение';
															|en = 'Add image'; fa = 'افزودن تصویر';
															|it = 'Aggiungi l''immagine';
															|pl = 'Dodaj obraz';
															|tr = 'Resim ekle'");
		Items.PicturesFile.TextColor				= StyleColors.NotSelectedPictureTextColor;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		Items.Barcode.Visible = False;
	Else
		Items.Barcode.Visible = True;
	EndIf;
	
	ProductsLocalization.CustomizeFormAndUpdateCard(ThisObject, VisibilityOfElements);
	
	
	ProductProfile = Catalogs.Products.TableDocumentOfProductCard(
		Object, VisibilityAndHeaderSettings, False);
	
EndProcedure

#Region SettingVisibilityOfGroupsAndElementsModeSwitch

&AtClient
Procedure ConfigureFormVisibilityOnChange(Item)
	
	VisibilityModeShowHighPriorityOnlyBefore = VisibilityModeShowHighPriorityOnly;
	
	If ConfigureFormVisibility = "ShowAllItems" Then
		VisibilityModeShowHighPriorityOnly = False;
		GroupBy                           = False;
	ElsIf ConfigureFormVisibility = "ShowMain" Then
		VisibilityModeShowHighPriorityOnly = True;
		GroupBy                           = False;
	Else
		VisibilityModeShowHighPriorityOnly = False;
		GroupBy                           = True;
	EndIf;
	
	If VisibilityModeShowHighPriorityOnlyBefore <> VisibilityModeShowHighPriorityOnly Then
		CustomizeFormAndUpdateCard();
	EndIf;
	
	HideRevealAllGroups(GroupBy);
	
EndProcedure

&AtServer
Procedure HideRevealAllGroups(GroupBy)
	
	NamesOfGroupsToCollapse = NamesOfGroupsToCollapse();
	
	For Each GroupName In NamesOfGroupsToCollapse Do
		ChangeConvolutionOfGroup(GroupName, GroupBy);
	EndDo;
	
EndProcedure

&AtServer
Procedure ChangeConvolutionOfGroup(GroupName, GroupBy)
	
	CollapsibleGroupElement = Items[GroupName];
	
	If GroupBy Then
		CollapsibleGroupElement.Hide();
	Else
		CollapsibleGroupElement.Show();
	EndIf;
	
EndProcedure

&AtServer
Procedure ExpandCollapsibleGroup(GroupName)
	
	ParentGroup1 = Items[GroupName].Parent; // FormGroup
	
	If ParentGroup1 = ThisObject Then
		Return;
	EndIf;
	
	ParentGroupName		= ParentGroup1.Name;
	NamesOfGroupsToCollapse	= NamesOfGroupsToCollapse();
	
	If NamesOfGroupsToCollapse.Find(ParentGroupName) = Undefined Then
		ExpandCollapsibleGroup(ParentGroupName);
	Else
		ChangeConvolutionOfGroup(ParentGroupName, False);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region UnitsOfMeasurement

&AtServer
Procedure ConfigureMeasureElements(Measure, ElementVisibilityStructure, StructureOfElementHeaders, VisibilityModeShowHighPriorityOnly)
	
	MeasureProperties = MeasureProperties(Measure);
	
	AccessibilityMeasures = AccessRight("Edit", Metadata.Catalogs.Products.Attributes[MeasureProperties.UnitOfMeasure]);
	
	If Not ValueIsFilled(Object.UnitOfMeasure) Then
		VisibilityMeasures = Object[MeasureProperties.Use];
		Items[MeasureProperties.Use].Enabled = AccessibilityMeasures;
	Else
		
		UnitType_ = "";
		
		If Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Object.UnitOfMeasure, UnitType_)
			And Measure = UnitType_ Then
			AccessibilityMeasures = False;
			Items[MeasureProperties.Use].Enabled = AccessibilityMeasures;
			VisibilityMeasures = False;
		Else
			
			Items[MeasureProperties.Use].Enabled = AccessibilityMeasures;
			VisibilityMeasures = Object[MeasureProperties.Use] And ElementVisibilityStructure[MeasureProperties.Use];
		EndIf;
	EndIf;
	
	ElementVisibilityStructure.Insert(MeasureProperties.Indent, VisibilityMeasures);
	ElementVisibilityStructure.Insert(MeasureProperties.Label, VisibilityMeasures);
	ElementVisibilityStructure.Insert(MeasureProperties.Denominator, VisibilityMeasures);
	ElementVisibilityStructure.Insert(MeasureProperties.Numerator, VisibilityMeasures);
	ElementVisibilityStructure.Insert(MeasureProperties.UnitOfMeasure, VisibilityMeasures);
	ElementVisibilityStructure.Insert(MeasureProperties.CanBeSpecifiedInDocuments, VisibilityMeasures);
	
	If Measure = "Weight" Then
		CaptionText = NStr("vi = '%UnitOfMeasure% cân nặng';
							|ru = '%UnitOfMeasure% весит';
							|en = '%UnitOfMeasure% weighs'; fa = '%UnitOfMeasure% weighs';
							|it = '%UnitOfMeasure% pesa';
							|pl = '%UnitOfMeasure% waży';
							|tr = '%UnitOfMeasure% ağırlığında'");
	ElsIf Measure = "VolumeM3" Then
		CaptionText = NStr("vi = '%UnitOfMeasure% chiếm khối lượng';
							|ru = '%UnitOfMeasure% занимает объем';
							|en = '%UnitOfMeasure% is of volume'; fa = '%UnitOfMeasure% is of volume';
							|it = '%UnitOfMeasure% occupa volume';
							|pl = '%UnitOfMeasure% zajmuje objętość';
							|tr = '%UnitOfMeasure% hacmi kapsıyor'");
	ElsIf Measure = "AreaTypeOfMeasurement" Then
		CaptionText = NStr("vi = '%UnitOfMeasure% chiếm diện tích';
							|ru = '%UnitOfMeasure% имеет площадь';
							|en = '%UnitOfMeasure% has an area of'; fa = '%UnitOfMeasure% has an area of';
							|it = '%UnitOfMeasure% ha superficie';
							|pl = '%UnitOfMeasure% ma powierzchnię';
							|tr = '%UnitOfMeasure% alanı mevcut'");
	ElsIf Measure = "Length" Then
		CaptionText = NStr("vi = '%UnitOfMeasure% chiếm chiều dài';
							|ru = '%UnitOfMeasure% имеет длину';
							|en = '%UnitOfMeasure% is of length'; fa = '%UnitOfMeasure% is of length';
							|it = '%UnitOfMeasure% ha lunghezza';
							|pl = '%UnitOfMeasure% ma długość';
							|tr = '%UnitOfMeasure% uzunluğu mevcut'");
	EndIf;
	
	CaptionText = StrReplace(CaptionText, "%UnitOfMeasure%", String(Object.UnitOfMeasure));
	StructureOfElementHeaders.Insert(MeasureProperties.Label, CaptionText);
	
	ValuePresentationText = NStr("vi = 'Có thể chỉ định số lượng %UnitOfMeasure_% trong chứng từ';
								|ru = 'Можно указывать количество в %UnitOfMeasure_% в документах';
								|en = 'You can specify quantity in %UnitOfMeasure_% in the documents'; fa = 'You can specify quantity in %UnitOfMeasure_% in the documents';
								|it = 'È possibile indicare la quantità in %UnitOfMeasure_% nei documenti';
								|pl = 'Można określać ilość w %UnitOfMeasure_% w dokumentach';
								|tr = 'Belgelerde miktar %UnitOfMeasure_% olarak belirtilebilir'");
	ValuePresentationText = StrReplace(ValuePresentationText, "%UnitOfMeasure_%", String(Object[MeasureProperties.UnitOfMeasure]));
	
	Items[MeasureProperties.CanBeSpecifiedInDocuments].Enabled = AccessibilityMeasures;
	Items[MeasureProperties.CanBeSpecifiedInDocuments].ChoiceList[1].Presentation = ValuePresentationText;
	
EndProcedure

&AtServer
Procedure ConvertCanBeSpecifiedInDocumentsAsString(Measure)
	
	MeasureProperties = MeasureProperties(Measure);
	If Object[MeasureProperties.CanBeSpecifiedInDocuments] Then
		ThisObject[MeasureProperties.YouCanSpecifyStringInDocuments] = "CanBeSelectedInDocuments";
	Else
		ThisObject[MeasureProperties.YouCanSpecifyStringInDocuments] = "ForReference";
	EndIf;		
	
EndProcedure

&AtClient
Procedure MeasureCanBeSpecifiedInDocumentsWhenChanging(Measure)
	
	MeasureProperties = MeasureProperties(Measure);
	If ThisObject[MeasureProperties.YouCanSpecifyStringInDocuments] = "CanBeSelectedInDocuments" Then
		Object[MeasureProperties.CanBeSpecifiedInDocuments] = True;
	Else
		Object[MeasureProperties.CanBeSpecifiedInDocuments] = False;
	EndIf;		
	
EndProcedure

&AtServer
Procedure HowToUseWhenChangingServer(Measure)
	
	MeasureProperties = MeasureProperties(Measure);
	If Object[MeasureProperties.Use] Then
		Object[MeasureProperties.Denominator] = 1;
		Object[MeasureProperties.UnitOfMeasure] = ProductsServer.DefaultUnitOfMeasurement(Measure);
	EndIf;
	
	CustomizeFormAndUpdateCard();
	
EndProcedure

&AtServer
Procedure UnitOfMeasureOnChangeServer()
	
	If Object.UnitFactorForReports = 1
		Or Object.UnitFactorForReports = 0 Then
		Object.UnitForReports = Object.UnitOfMeasure;
	EndIf;
	
	If Object.UnitForReports = Object.UnitOfMeasure Then
		Object.UnitFactorForReports = 1;
	EndIf;
	
	UnitType_ = "";
	
	ThisIsADimensionalUnit = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Object.UnitOfMeasure, UnitType_);
	Catalogs.Products.WorkOutLogicOfFillingMeasure(Object, ThisIsADimensionalUnit, UnitType_, UnitType_);
	
	If ThisIsADimensionalUnit Then
		Object.SuppliedInReusablePackage   = False;
	EndIf;
	
	CustomizeFormAndUpdateCard();
	
EndProcedure

#EndRegion

#Region ImportAccountingAndTraceability

&AtClient
Procedure FillInImportAndTraceabilityDetails()
	
	TraceabilityDetails = ProductsClientServer.DefaultTraceabilityDetails();
	
	If ValueIsFilled(Object.FEACNCode) Then
		TraceabilityDetails = TraceabilityDetails(Object.FEACNCode);
	EndIf;
	
	Object.FEACNUnitOfMeasure = TraceabilityDetails.UnitOfMeasure;
	
	ProductsClientServerLocalization.FillInImportAndTraceabilityDetails(Object,
																					TraceabilityDetails);
	
EndProcedure

&AtServerNoContext
Function TraceabilityDetails(FEACNCode)
	
	Return Catalogs.Products.TraceabilityDetails(FEACNCode);
	
EndFunction

#EndRegion

#Region CheckingUniqueness

&AtServer
Procedure CheckRequiredBankingDetails(Cancel)
	
	ErrorText = NStr("vi = 'Chưa điền trường ""%AttributeName%""';
					|ru = 'Поле ""%AttributeName%"" не заполнено';
					|en = '""%AttributeName%"" is required'; fa = '""%AttributeName%"" is required';
					|it = 'Il campo ""%AttributeName%"" non è compilato';
					|pl = 'Nie wypełniono pola ""%AttributeName%""';
					|tr = '""%AttributeName%"" alanı doldurulmadı'");
	
	If Not ValueIsFilled(Object.ProductKind) Then
		
		MessageText = StrReplace(ErrorText, "%AttributeName%", NStr("vi = 'Dạng mặt hàng';
																	|ru = 'Вид номенклатуры';
																	|en = 'Item kind'; fa = 'نوع قلم';
																	|it = 'Tipo di articolo';
																	|pl = 'Rodzaj pozycji';
																	|tr = 'Ürün türü'"));
		Common.MessageToUser(MessageText, , "Object.ProductKind", , Cancel);
		
		Return;
		
	EndIf;

	ProductsLocalization.CheckRequiredBankingDetails(ThisObject, Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	ObjectToFillIn = Object;
	ProductsLocalization.AddFormObject(ThisObject, ObjectToFillIn);

	AttributesNotToCheck	= Catalogs.Products.AttributesNotToCheck(ObjectToFillIn);

	ProductsLocalization.RestoreFormObject(ThisObject, ObjectToFillIn);

	FormAttributes			= Catalogs.Products.DetailsOfSettingsTableForm();
	
	For Each TableRow In AttributeSettingTable Do
		
		If TableRow.IsAddlAttribute Then
			Continue;
		EndIf;
		
		If Not TableRow.RequiredToFill
			Or (TableRow.AttributeName <> "UnitOfMeasure"
				And AttributesNotToCheck.Find(TableRow.AttributeName) <> Undefined) Then
			
			Continue;
			
		EndIf;
		
		IsFormAttribute	= FormAttributes.Get(TableRow.AttributeName) <> Undefined;
		AttributeValue	= ?(IsFormAttribute,
								ThisObject[TableRow.AttributeName],
								Object[TableRow.AttributeName]);
		AttributePath1		= TableRow.DataPath;
		
		If Not ValueIsFilled(AttributeValue) Then
			
			MessageText = StrReplace(ErrorText, "%AttributeName%", TableRow.Presentation);
			
			If TableRow.AttributeName = "PicturesFile" Then
				
				If Not ValueIsFilled(Object.Ref)
						And Not ValueIsFilled(PictureAddress)
					Or ValueIsFilled(Object.Ref) Then
					
					Common.MessageToUser(MessageText, , AttributePath1, , Cancel);
					
				EndIf;
				
				Continue;
				
			EndIf;
			
			If TableRow.AttributeName = "DescriptionFileForWebsite" Then
				
				If Not ValueIsFilled(Object.Ref)
						And Not ValueIsFilled(PathToTheDescriptionFile)
					Or ValueIsFilled(Object.Ref) Then
					
					Common.MessageToUser(MessageText, , AttributePath1, , Cancel);
					
				EndIf;
				
				Continue;
				
			EndIf;
			
			If TableRow.AttributeName = "Barcode" Then
				If Not ValueIsFilled(Object.Ref) Then
					Common.MessageToUser(MessageText, , AttributePath1, , Cancel);
				EndIf;
				
				Continue;
			EndIf;
			
			FormField = ?(IsFormAttribute, TableRow.AttributeName, "Object." + TableRow.AttributeName);
			
			Common.MessageToUser(MessageText, , FormField, ,Cancel);
			
		EndIf;
	
	EndDo;
	
	CheckedAttributes = New Array;
	
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	If Cancel And Not VisibilityModeShowHighPriorityOnly Then
		ConfigureFormVisibility				= "ShowAllItems";
		VisibilityModeShowHighPriorityOnly	= False;
		
		CustomizeFormAndUpdateCard();
		HideRevealAllGroups(False);
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckAbilityToCreateChangeToItemByAccessGroup(Cancel)
	
	If Not GetFunctionalOption("UseItemAccessGroups") Then
		Return;
	EndIf;
	
	MessageText = "";
	
	If ValueIsFilled(Object.AccessGroup) Then
		
		If Not Catalogs.ItemAccessGroups.HasUpdateRight(New Structure("AccessGroup, Ref", Object.AccessGroup, Object.Ref)) Then
			
			MessageText = NStr("vi = 'Không đủ quyền để tạo mặt hàng theo nhóm truy cập này % Nhóm truy cập%';
								|ru = 'Недостаточно прав на создание номенклатуры по этой группе доступа %AccessGroup%';
								|en = 'Insufficient rights to create products by this access group %AccessGroup%'; fa = 'Insufficient rights to create products by this access group %AccessGroup%';
								|it = 'Permessi insufficienti per la creazione dell''articolo secondo questo gruppo d''accesso %AccessGroup%';
								|pl = 'Brak uprawnień do tworzenia towarów dla tej grupy dostępu %AccessGroup%';
								|tr = 'Bu erişim grubu %AccessGroup% için bir öğe oluşturmak için yetersiz erişim yetkisi'");
			MessageText = StrReplace(MessageText, "%AccessGroup%", Object.AccessGroup);
			
		EndIf;
		
	Else
		MessageText = NStr("vi = 'Trong dạng mặt hàng ""%AccessGroup%"" chưa chỉ định nhóm truy cập. Không thể tạo mặt hàng dạng này.';
							|ru = 'В виде номенклатуры ""%AccessGroup%"" не указана группа доступа. Невозможно создать номенклатуру этого вида.';
							|en = 'Access group is not specified for item kind ""%AccessGroup%"". Cannot create this kind of items.'; fa = 'Access group is not specified for item kind ""%AccessGroup%"". Cannot create this kind of items.';
							|it = 'Nel tipo di articolo ""%AccessGroup%"" non è stato specificato un gruppo d''accesso. Impossibile creare un articolo di questo tipo.';
							|pl = 'W rodzaju towaru ""%AccessGroup%"" nie określono grupy dostępu. Utworzenie towaru tego rodzaju nie jest możliwe.';
							|tr = 'Öğe türünde ""%AccessGroup%"" erişim grubu belirtilmiyor. Bu tür öğe oluşturmak mümkün değildir.'");
		MessageText = StrReplace(MessageText, "%AccessGroup%", Object.AccessGroup);
	EndIf;
	
	If ValueIsFilled(MessageText) Then
		Common.MessageToUser(MessageText,,"Object.ProductKind",,Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckUniquenessOfElementByBarcode()
	
	If Not ValueIsFilled(Barcode) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("UseNonUniqueItemBarcodes") Then
		QueryText =
		"SELECT TOP 1
		|	ItemsBarcodes.Products AS Ref
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON ItemsBarcodes.Products = CatalogProducts.Ref
		|		
		|		INNER JOIN Catalog.ItemKinds.AttributesForProductsControl AS UniquenessControlDetails
		|		ON CatalogProducts.ProductKind = UniquenessControlDetails.Ref
		|			AND UniquenessControlDetails.AttributeName = &PropsNameBarcode
		|			AND UniquenessControlDetails.Uniqueness
		|WHERE
		|	ItemsBarcodes.Barcode = &Barcode
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	ItemsBarcodes.Products AS Ref
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON ItemsBarcodes.Products = CatalogProducts.Ref
		|		
		|		LEFT JOIN Catalog.ItemKinds.AttributesForProductsControl AS UniquenessControlDetails
		|		ON CatalogProducts.ProductKind = UniquenessControlDetails.Ref
		|			AND UniquenessControlDetails.AttributeName = &PropsNameBarcode
		|			AND NOT UniquenessControlDetails.Uniqueness
		|WHERE
		|	ItemsBarcodes.Barcode = &Barcode
		|	AND NOT ISNULL(UniquenessControlDetails.Uniqueness, FALSE)
		|	AND TRUE IN
		|			(SELECT
		|				TRUE
		|			FROM
		|				Catalog.ItemKinds.AttributesForProductsControl AS ControlAttributes
		|			WHERE
		|				ControlAttributes.Ref = &ProductKind
		|				AND ControlAttributes.AttributeName = &PropsNameBarcode
		|				AND ControlAttributes.Uniqueness)
		|";
	Else
		QueryText =
		"SELECT TOP 1
		|	ItemsBarcodes.Products AS Ref
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|WHERE
		|	ItemsBarcodes.Barcode = &Barcode";
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Barcode",				TrimAll(Barcode));
	Query.SetParameter("PropsNameBarcode",	"Barcode");
	Query.SetParameter("ProductKind",		Object.ProductKind);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	Filter			= New Structure("Ref", Selection.Ref);
	FoundRows	= TableFound.FindRows(Filter);
	
	If FoundRows.Count() = 0 Then
		NewRow = TableFound.Add();
		NewRow.Ref				= Selection.Ref;
		NewRow.FoundByBarcode	= True;
	Else
		FoundRows[0].FoundByBarcode = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckUniquenessByWorkingName()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Products.Ref AS Ref
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	Products.Ref <> &Ref
	|	AND Products.Description = &Description
	|	AND NOT Products.IsFolder";
	
	Query.SetParameter("Ref",       Object.Ref);
	Query.SetParameter("Description", Object.Description);
	
	Selection = Query.Execute().Select();
	
	Filter = New Structure("Ref");
	
	While Selection.Next() Do
		
		Filter.Ref = Selection.Ref;
		
		FoundRows = TableFound.FindRows(Filter);
		
		If FoundRows.Count() = 0 Then
			
			NewRow = TableFound.Add();
			
			NewRow.Ref                = Selection.Ref;
			NewRow.FoundByName = True;
			
		Else
			
			FoundRows[0].FoundByName = True;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function CheckUniquenessOfGivenName(ThisIsARecord, Cancel = False)
	
	If Not Cancel Then
		CheckAbilityToCreateChangeToItemByAccessGroup(Cancel);
	EndIf;
		
	If Cancel Then
		Return Undefined;
	EndIf;
	
	TableFound.Clear();
	
	If Constants.ControlItemUniquenessByCombinationValuesAttributes.Get()
		And Not ValueIsFilled(Object.Ref)
		And Not UniquenessControlBeforeWritingIsCompleted Then
		
		Catalogs.Products.CheckUniquenessOfElementByItsDetails(ThisObject);
		
		If ValueIsFilled(Barcode) Then
			CheckUniquenessOfElementByBarcode();
		EndIf;
		
	EndIf;
	
	If ThisIsARecord Then
		
		FormationOptions = New Array;
		
		If GenerateWorkName Then
			FormationOptions.Add("Working");
		EndIf;
			
		If GeneratePrintName Then
			FormationOptions.Add("ForPrint");
		EndIf;
		
		FillingResult = FillInANameFromTemplateServer(StrConcat(FormationOptions, ", "));
		If FillingResult.HasErrors Then
			Common.MessageToUser(FillingResult.ErrorText,, "Description", "Object");
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(Object.Description)
		And Constants.ControlUniquenessOfWorkingNamesOfProductsAndItemVariants.Get() Then
			
		CheckUniquenessByWorkingName();
	
	ElsIf Not ValueIsFilled(Object.Description)
		And ThisIsARecord Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""Tên gọi làm việc""';
							|ru = 'Поле ""Рабочее наименование"" не заполнено';
							|en = '""Working title"" is required'; fa = '""Working title"" is required';
							|it = 'Il campo ""Titolo lavorativo"" non è compilato';
							|pl = 'Nie wypełniono pola ""Nazwa robocza""';
							|tr = '""Çalışma tanımı"" alanı doldurulmadı'");
		Common.MessageToUser(MessageText,, "Description", "Object");
		Cancel = True;
	
	EndIf;
	
	TableFound.Sort("Ref");
	If TableFound.Count() > 0 Then
		
		Cancel = True;
		Return PutToTempStorage(TableFound.Unload(), UUID);
		
	Else
		
		Return Undefined;
		
	EndIf;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure ConfigureAvailabilityOfBlockedBankingDetails()

	Items.UsePackages.ReadOnly = Object.UsePackages;
	Items.UseOfPackagesIndividualSet.ReadOnly = Object.UsePackages;
	Items.UsingPackagesCommonSet.ReadOnly = Object.UsePackages;
	Items.PackagingGroup.ReadOnly = Object.UsePackages;
	
	ProductsLocalization.ConfigureAvailabilityOfBlockedBankingDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure FillByCopyObject()
	
	If CreationParameters().Property("Quality")
		And ValueIsFilled(CreationParameters().Quality)
		And CreationParameters().Quality <> Enums.QualityLevels.New Then
		
		AutoTitle = False;
		
		TitleText = NStr("vi = 'Tạo mặt hàng đối với hàng hóa hư hỏng ""%ProductName%"".';
						|ru = 'Создание номенклатуры для испорченного товара ""%ProductName%"".';
						|en = 'Create products for spoiled goods ""%ProductName%"".'; fa = 'Create products for spoiled goods ""%ProductName%"".';
						|it = 'Creazione di un articolo per la merce rovinata ""%ProductName%"".';
						|pl = 'Tworzenie nazwy towarowej dla uszkodzonego towaru ""%ProductName%"".';
						|tr = 'Hasarlı ürünler için bir öğe oluşturma ""%ProductName%"".'");
		Title = StrReplace(TitleText, "%ProductName%", String(Object.Description));
		
		Object.Quality              = CreationParameters().Quality;
		Object.WarehouseGroup       = Catalogs.WarehouseGroupsOfItems.EmptyRef();
		Object.PriceGroup         = Catalogs.PriceGroups.EmptyRef();
		Object.PicturesFile          = Catalogs.ProductsAttachedFiles.EmptyRef();
		Object.DescriptionFileForWebsite  = Catalogs.ProductsAttachedFiles.EmptyRef();
		
		StructureCreationParameters = New Structure(CreationParameters());
		StructureCreationParameters.Description       = Object.Description + ", " + String(Object.Quality); 
		
		For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
			If AdditionalLanguageIsUsed.Value = True Then
				AttributeName = StrTemplate("Description%1", AdditionalLanguageIsUsed.Key);
				StructureCreationParameters[AttributeName] = Object[AttributeName] + ", " + String(Object.Quality);
			EndIf;
		EndDo;
		
		StructureCreationParameters.DescriptionFull = Object.DescriptionFull + ", " + String(Object.Quality);
		CreationParameters = New FixedStructure(StructureCreationParameters);
		
	EndIf;
	
	If GetFunctionalOption("UseExcisableGoods")
		And ExcisableGoodsAccounting.ThisIsExcisableProduct(CreationParameters.CopySource) Then
		Items.TextOfDataOnUnrecordedExciseCategories.Visible = True;
	EndIf;
	
	If ValueIsFilled(Object.PicturesFile)
		Or ValueIsFilled(Object.DescriptionFileForWebsite) Then
		
		CopyAttachedFiles(CreationParameters().CopySource.PicturesFile,
										CreationParameters().CopySource.DescriptionFileForWebsite);
		
		Object.PicturesFile			= Catalogs.ProductsAttachedFiles.EmptyRef();
		Object.DescriptionFileForWebsite	= Catalogs.ProductsAttachedFiles.EmptyRef();
		
	EndIf;
	
	Object.AccessGroup	= Catalogs.ItemAccessGroups.EmptyRef();
	Object.Code				= "";
	Object.SearchCode		= "";
	Object.DeletionMark	= False;
	
	ProductsLocalization.ConfigureAvailabilityOfBlockedBankingDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInByCreationParameters()
	
	TMCommonUseClientServer.FillInValuesOfEmptyProperties(Object, CreationParameters());
	
	If CreationParameters().Property("SupplierProductName")
		And ValueIsFilled(CreationParameters().SupplierProductName) Then
		
		StructureCreationParameters = New Structure(CreationParameters());
		StructureCreationParameters.Description = Object.Description;
		CreationParameters = New FixedStructure(StructureCreationParameters);
		
	EndIf;
	
	If CreationParameters().Property("SupplierProductItem")
		And ValueIsFilled(CreationParameters().SupplierProductItem) 
		And Not ValueIsFilled(Object.SKU)Then
		Object.SKU = CreationParameters().SupplierProductItem;
	EndIf;
	
	If IsBlankString(Barcode)
		And CreationParameters().Property("Barcode") Then
		Barcode = CreationParameters().Barcode;
	EndIf;
	
	If Not ValueIsFilled(Object.ProductKind)
		Or Common.ObjectAttributeValue(Object.ProductKind, "IsFolder") Then
		Object.ProductKind = Catalogs.ItemKinds.DefaultProductType();
	EndIf;
	
	ProductsLocalization.FillInByCreationParameters(Object, CreationParameters());
	
	FillingByCopySource = CreationParameters().Property("CopySource")
										And ValueIsFilled(CreationParameters().CopySource);
	
	ProductTypeWhenChangedOnServer(FillingByCopySource);
	
	If ValueIsFilled(Object.ProductKind) Then
		
		If CreationParameters().Property("AddressOfParameterTable")
			And ValueIsFilled(CreationParameters().AddressOfParameterTable)
			And IsTempStorageURL(CreationParameters().AddressOfParameterTable) Then
			
			AddlAttributesTable = New ValueTable;
			AddlAttributesTable.Columns.Add("AttributeName", New TypeDescription("String",,,New StringQualifiers(255)));
			
			TableOfPropsValues = GetFromTempStorage(CreationParameters().AddressOfParameterTable);
			AttributesArray = TableOfPropsValues.FindRows(New Structure("IsAddlAttribute", False));
			
			For Each ArrayElement In AttributesArray Do
				If Not ValueIsFilled(Object[ArrayElement.AttributeName]) Then
					Object[ArrayElement.AttributeName] = ArrayElement.FilterValue;
				EndIf;
			EndDo;
			
			AddlAttributesArray = TableOfPropsValues.FindRows(New Structure("IsAddlAttribute", True));
			
			If GetFunctionalOption("UseAdditionalAttributesAndInfo") 
				And AddlAttributesArray.Count() > 0 Then
				
				For Each ArrayElement In AddlAttributesArray Do
					
					NewRow = AddlAttributesTable.Add();
					NewRow.AttributeName = ArrayElement.AttributeName;
					
				EndDo;
				
				Query = New Query;
				Query.Text =
				"SELECT
				|	AddlAttributesTable.AttributeName
				|INTO PropertyNameTable
				|FROM
				|	&AddlAttributesTable AS AddlAttributesTable
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	PropertyNameTable.AttributeName AS AttributeName,
				|	AdditionalAttributeSets.Property AS Property
				|FROM
				|	PropertyNameTable AS PropertyNameTable
				|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AdditionalAttributeSets
				|		ON PropertyNameTable.AttributeName = AdditionalAttributeSets.Property.Description
				|WHERE
				|	AdditionalAttributeSets.Ref = &AttributesSet";
				
				Query.SetParameter("AddlAttributesTable", AddlAttributesTable);
				Query.SetParameter("AttributesSet",      ProductKindAttributes.PropertiesSet);
				
				PropertiesTable = Query.Execute().Unload();
				TheStructureOfTheSearch = New Structure("AttributeName");
				
				For Each TableRow In PropertiesTable Do
					
					ValueSearchStructure_ = New Structure("Property", TableRow.Property);
					RowsArray = ThisObject.PropertiesAdditionalAttributeDetails.FindRows(ValueSearchStructure_);
					PropertyDetails = RowsArray[0];
					DataPath = PropertyDetails.ValueAttributeName;
					
					TheStructureOfTheSearch.AttributeName = TableRow.AttributeName;
					ArrayOfStringsValue = TableOfPropsValues.FindRows(TheStructureOfTheSearch);
					AttributeValue = ArrayOfStringsValue[0].FilterValue;
					If Not ValueIsFilled(ThisObject[DataPath]) Then
						ThisObject[DataPath] = AttributeValue;
					EndIf;
					
				EndDo;
				
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Returns:
//	FixedStructure:
//		* AddressOfParameterTable - String
//		* SupplierProductItem - String
//		* CopySource - Structure
//		* Quality - EnumRef.QualityLevels
//		* Description - String
//		* SupplierProductName - String
//		* DescriptionFull - String
//		* Barcode - String
//
&AtServer
Function CreationParameters()
	
	Return CreationParameters;
	
EndFunction

// Returns:
//	Structure:
//		* FullName - String - file name.
//		* BaseName - String - file name without extension.
//		* Extension - String - file extension.
//
&AtClientAtServerNoContext
Function DescriptionOfFileData()
	
	Result = New Structure;
	Result.Insert("FullName");
	Result.Insert("BaseName");
	Result.Insert("Extension");
	
	Return Result;
	
EndFunction

// Parameters:
// 	PicturesFile - CatalogRef.ProductsAttachedFiles
// 	FileDescription_ - CatalogRef.ProductsAttachedFiles
&AtServer
Procedure CopyAttachedFiles(PicturesFile, FileDescription_)
	
	If ValueIsFilled(PicturesFile) Then
		
		AttachedFileData = FilesOperations.FileData(PicturesFile);
		
		ImageFileData = DescriptionOfFileData();
		ImageFileData.FullName			= AttachedFileData.FileName;
		ImageFileData.BaseName	= StrReplace(AttachedFileData.FileName,
																"." + AttachedFileData.Extension,
																"");
		ImageFileData.Extension			= AttachedFileData.Extension;
		
		// Conversion of the attached file of the "old" format
		FileBinaryData = GetFromTempStorage(AttachedFileData.RefToBinaryFileData);
		ConvertPictureToBinaryData(FileBinaryData);
		
		If Not ValueIsFilled(FileBinaryData) Then
			ImageFileData = Undefined;
		EndIf;
		
		PictureAddress = PutToTempStorage(FileBinaryData, UUID);
		
	EndIf;

	If ValueIsFilled(FileDescription_) Then
		
		AttachedFileData = FilesOperations.FileData(FileDescription_);
		
		HTMLFileData = DescriptionOfFileData();
		HTMLFileData.FullName			= AttachedFileData.FileName;
		HTMLFileData.BaseName	= StrReplace(AttachedFileData.FileName,
															"." + AttachedFileData.Extension,
															"");
		HTMLFileData.Extension			= AttachedFileData.Extension;
		
		FileBinaryData = GetFromTempStorage(AttachedFileData.RefToBinaryFileData);
		
		HTMLDescriptionAddress	= PutToTempStorage(FileBinaryData, UUID);
		PathToTheDescriptionFile	= String(FileDescription_);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	ImageObject - BinaryData, Picture - 
&AtServerNoContext
Procedure ConvertPictureToBinaryData(ImageObject)
	
	If TypeOf(ImageObject) <> Type("Picture") Then
		Return;
	EndIf;
	
	TempFile = GetTempFileName();
	ImageObject.Write(TempFile);
	
	ImageObject = New BinaryData(TempFile);
	
	Try
		DeleteFiles(TempFile);
	Except
		EventName = NStr("vi = 'Sao chép mặt hàng. Xóa tệp tạm thời.';
						|ru = 'Копирование номенклатуры. Удаление временного файла.';
						|en = 'Copy products. Delete temporary file.'; fa = 'Copy products. Delete temporary file.';
						|it = 'Copiatura dell''articolo. Eliminazione del file temporaneo.';
						|pl = 'Kopiowanie nazwy towarowej. Usuwanie pliku tymczasowego.';
						|tr = 'Öğe kopyalama. Geçici bir dosyayı silme.'",
							Common.DefaultLanguageCode());
		
		WriteLogEvent(EventName,
								EventLogLevel.Error,
								,
								,
								ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

&AtServer
Procedure ProcessRecordOfProductOfDifferentQuality()
			 
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	CatProducts.ThereAreGoodsOfOtherQuality AS ThereAreProductsOfDifferentQualityInDatabase,
	|	CASE
	|		WHEN AnotherQualityGoods.OtherQualityGoods IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreGoodsOfDifferentQualityInFact
	|FROM
	|	Catalog.Products AS CatProducts
	|		LEFT JOIN InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|		ON CatProducts.Ref = AnotherQualityGoods.Products
	|WHERE
	|	CatProducts.Ref = &Products
	|	AND CatProducts.ThereAreGoodsOfOtherQuality <> CASE
	|			WHEN AnotherQualityGoods.OtherQualityGoods IS NULL 
	|				THEN FALSE
	|			ELSE TRUE
	|		END";
	
	Query.SetParameter("Products",Object.Ref);	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		If Object.ThereAreGoodsOfOtherQuality <> Selection.ThereAreGoodsOfDifferentQualityInFact Then
			Object.ThereAreGoodsOfOtherQuality = Selection.ThereAreGoodsOfDifferentQualityInFact;
		EndIf;
		
		Write();
	EndIf;
	
	CustomizeFormAndUpdateCard();
	
EndProcedure

&AtServer
Function FillInANameFromTemplateServer(FormationOptions)
	
	FillingResult = New Structure;
	FillingResult.Insert("HasErrors", False);
	FillingResult.Insert("ErrorText", "");
	
	If Not ValueIsFilled(FormationOptions) Then
		Return FillingResult;
	EndIf;
	
	PropertyManager.BeforeWriteAtServer(ThisObject, Object);
	CatalogObject = FormAttributeToValue("Object");
	
	OptionsArray = StrSplit(FormationOptions, ", ", False);
	
	If OptionsArray.Find("Working") <> Undefined Then
		
		TemplateQuality		= "[Quality]";
		DescriptionTemplate	= ProductKindAttributes.WorkingNameTemplateOfProductItem;
		
		If ValueIsFilled(Object.Quality)
			And Object.Quality <> Enums.QualityLevels.New
			And StrFind(DescriptionTemplate, TemplateQuality) = 0 Then
			
			DescriptionTemplate = DescriptionTemplate + " + "", "" + " + TemplateQuality;
			
		EndIf;
		
		NewWorkingName = ProductsServer.NameByTemplate(DescriptionTemplate, CatalogObject);
		
		Object.Description = NewWorkingName;
		CatalogObject.Description = Object.Description;
		
		WorkingNameLength = StrLen(NewWorkingName);
		MaximumWorkingNameLength = Metadata.Catalogs.Products.DescriptionLength;
		
		If WorkingNameLength > MaximumWorkingNameLength Then
			
			If CurrentLanguage().LanguageCode = "ru" Then
				
				PresentationsArray = GetStringDeclensionsByNumber("char", WorkingNameLength,, "L=ru_RU");
				If PresentationsArray.Count() > 0 Then
					LengthPresentation = PresentationsArray.Get(0);
				Else
					LengthPresentation = String(WorkingNameLength);
				EndIf;
				PresentationsArray = GetStringDeclensionsByNumber("char", MaximumWorkingNameLength,, "L=ru_RU");
				If PresentationsArray.Count() > 0 Then
					MaximumLengthPresentation = PresentationsArray.Get(0);
				Else
					MaximumLengthPresentation = String(MaximumWorkingNameLength);
				EndIf;
				
			Else
				LengthPresentation             = String(WorkingNameLength);
				MaximumLengthPresentation = String(MaximumWorkingNameLength);
			EndIf;
			
			FillingResult.HasErrors = True;
			FillingResult.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Độ dài tên gọi đã tạo theo mẫu (%1) vượt quá hạn chế đã đặt (%2).';
					|ru = 'Длина сформированного по шаблону наименования (%1) превышает установленное ограничение (%2).';
					|en = 'The length of the name generated from the template (%1) exceeds the maximum value (%2).'; fa = 'The length of the name generated from the template (%1) exceeds the maximum value (%2).';
					|it = 'Длина сформированного по шаблону наименования (%1) превышает установленное ограничение (%2).';
					|pl = 'The length of the name generated from the template (%1) exceeds the maximum value (%2).';
					|tr = 'Şablon tarafından oluşturulan (%1) tanımının uzunluğu yapılandırılan (%2) sınırını aşmaktadır.'"),
				LengthPresentation,
				MaximumLengthPresentation
			);
			
		EndIf;
		
	EndIf;
	
	If OptionsArray.Find("ForPrint") <> Undefined Then
		
		Object.DescriptionFull = ProductsServer.NameByTemplate(
			ProductKindAttributes.NameTemplateForPrintingOfProductItem,
			CatalogObject
		);
		
	EndIf;
	
	RecalculateNeedForFormationOfNames(ThisObject);
	
	Return FillingResult;
	
EndFunction

&AtServer
Function FillInMultilingualNameCompleteByName()
	FillingResult = New Structure;
	FillingResult.Insert("Modified", True);
	FillingResult.Insert("StorageInTabularSection", True);
	FillingResult.Insert("DefaultLanguage", CurrentLanguage().LanguageCode );
	
	AttributeName = "Description";
	ValuesInDifferentLanguages = New Array;

	MeaningOfLanguage = New Structure;

	For Each Language In Metadata.Languages Do 
		If StrCompare(Language.LanguageCode, CurrentLanguage().LanguageCode) = 0 Then
			Continue;
		EndIf;
		Suffix = NationalLanguageSupportServer.LanguageSuffix(Language.LanguageCode);
		MeaningOfLanguage = New Structure;
		MeaningOfLanguage.Insert("LanguageCode", Language.LanguageCode);
		MeaningOfLanguage.Insert("AttributeValue", Object[AttributeName + "Language1"]);
		MeaningOfLanguage.Insert("Suffix", "Language1");
		ValuesInDifferentLanguages.Add(MeaningOfLanguage);
	EndDo; 
	FillingResult.Insert("ValuesInDifferentLanguages", ValuesInDifferentLanguages);
	
	Return FillingResult;
EndFunction

&AtServer
Function HeaderOfTemplateFormation()
	Return NStr("vi = '<Tên gọi làm việc sẽ được tạo theo khuôn mẫu>';
				|ru = '<Рабочее наименование будет сформировано по шаблону>';
				|en = '<Working title will be generated from the template>'; fa = '<Working title will be generated from the template>';
				|it = '<Il nome lavorativo sarà generato secondo il modello>';
				|pl = '<Nazwa robocza zostanie utworzona wg szablonu>';
				|tr = '<Çalışma tanımı numuneye göre oluşturulacaktır>'");
EndFunction

&AtServer
Function HeaderOfFormationAccordingToPrintTemplate()
	Return NStr("vi = '<Tên gọi để in sẽ được tạo theo khuôn mẫu>';
				|ru = '<Наименование для печати будет сформировано по шаблону>';
				|en = '<Print name will be generated from the template>'; fa = '<Print name will be generated from the template>';
				|it = '<Il nome per la stampa sarà generato secondo il modello>';
				|pl = '<Nazwa do druku zostanie utworzona wg szablonu>';
				|tr = '<Yazdırılacak adı şablona göre oluşturulacaktır>'");
EndFunction

&AtServer
Procedure SetAvailabilityOfEditingNames(HideAccessibility)
	
	HeaderOfTemplateFormation = HeaderOfTemplateFormation();
	HeaderOfFormationAccordingToPrintTemplate = HeaderOfFormationAccordingToPrintTemplate();
	
	If ProductKindAttributes.ProhibitEditingWorkingTitleOfItems Then
		
		Items.Description.AutoMarkIncomplete = False;
		Items.Description.MarkIncomplete = False;
		
	Else
		
		Items.Description.AutoMarkIncomplete = Not ValueIsFilled(ProductKindAttributes.WorkingNameTemplateOfProductItem);
		
	EndIf;
	
	If HideAccessibility Then
		
		If ProductKindAttributes.ProhibitEditingWorkingTitleOfItems Then
			Object.Description = ?(ValueIsFilled(Object.Description), Object.Description, HeaderOfTemplateFormation);
			NameTextColor = StyleColors.TextColorOfCanceledRowOfDocument;
		Else
			Object.Description = ?(ValueIsFilled(Object.Description), Object.Description, "");
			NameTextColor = StyleColors.FormTextColor;
		EndIf;
		
			Items.Description.ReadOnly = ProductKindAttributes.ProhibitEditingWorkingTitleOfItems;
			Items.Description.TextColor = NameTextColor;
		
		If ProductKindAttributes.RestrictNameChangeToPrintItems Then
			Object.DescriptionFull = ?(ValueIsFilled(Object.DescriptionFull), Object.DescriptionFull, HeaderOfFormationAccordingToPrintTemplate);
			NameTextColor = StyleColors.TextColorOfCanceledRowOfDocument;
		Else
			Object.DescriptionFull = ?(ValueIsFilled(Object.DescriptionFull), Object.DescriptionFull, "");
			NameTextColor = StyleColors.FormTextColor;
		EndIf;
		
		Items.DescriptionFull.ReadOnly = ProductKindAttributes.RestrictNameChangeToPrintItems;
		Items.DescriptionFull.TextColor = NameTextColor;
		
	Else
		
		If ProductKindAttributes.ProhibitEditingWorkingTitleOfItems And Object.Description = HeaderOfTemplateFormation Then
			Object.Description = ?(Object.Description = HeaderOfTemplateFormation, "", Object.Description);
		EndIf;
		
		If ProductKindAttributes.RestrictNameChangeToPrintItems And Object.DescriptionFull = HeaderOfFormationAccordingToPrintTemplate Then
			Object.DescriptionFull = ?(Object.DescriptionFull = HeaderOfFormationAccordingToPrintTemplate, "", Object.DescriptionFull);
		EndIf;
		
	EndIf;
	
	Items.FillInAPrintNameFromTemplate.Enabled = ValueIsFilled(ProductKindAttributes.NameTemplateForPrintingOfProductItem);
	
	Items.FillInAWorkNameFromTemplate.Enabled   = ValueIsFilled(ProductKindAttributes.WorkingNameTemplateOfProductItem);	                                                                                     

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	//
	If GetFunctionalOption("UseItemPackages") Then
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.UsingPackagesCommonSet.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = Items.UsePackages.ReadOnly;
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.UseOfPackagesIndividualSet.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = Items.UsePackages.ReadOnly;
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
	EndIf;
	
	SetConditionalAppearanceLocalization();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);

EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems(UpdateBankingDetails = True)
	
	If UpdateBankingDetails Then
		PropertyManager.UpdateAdditionalAttributesItems(ThisObject, , False);
	EndIf;
	
	For Each Item In Items.GroupAdditionalAttributes.ChildItems Do
		
		If Item.Type = FormFieldType.InputField Then
			
			If Item.MultiLine <> True Then
				
				Item.HorizontalStretch = False;
				
			Else
				
				Item.TitleLocation       = FormItemTitleLocation.Left;
				Item.VerticalStretch   = False;
				Item.HorizontalStretch = True;
				
			EndIf;
			
		ElsIf Item.Type = FormFieldType.CheckBoxField Then
			
			Item.TitleLocation = FormItemTitleLocation.Right;
			
		EndIf;
		
	EndDo;
	
	AttributesTable = Catalogs.Products.AttributeSettingTable(Object.ProductKind,
																			Object.ItemsType,
																			Object.AccountingFeature,
																			Object.UseVariants,
																			ProductKindAttributes.UseShelfLifeOnBatchRegistration,
																			"Products");
	
	AttributeSettingTable.Load(AttributesTable);
	
	Catalogs.Products.ConfigureFormUsingSettingsTable(ThisObject);
	
EndProcedure

&AtServer
Function NamesOfGroupsToCollapse()
	
	NamesOfGroupsToCollapse = New Array;
	
	NamesOfGroupsToCollapse.Add(Items.CollapsibleGroupMainAccountingParameters.Name);
	NamesOfGroupsToCollapse.Add(Items.CollapsibleGroupUnitsOfMeasurement.Name);
	NamesOfGroupsToCollapse.Add(Items.CollapsibleGroupAccountingFinancial.Name);
	NamesOfGroupsToCollapse.Add(Items.CollapsibleGroupPictureDescription_2.Name);
	NamesOfGroupsToCollapse.Add(Items.CollapsibleGroupAdditionalAttributes.Name);
	NamesOfGroupsToCollapse.Add(Items.CollapsibleGroupPlanningAndMarketing.Name);
	NamesOfGroupsToCollapse.Add(Items.CollapsibleGroupSupply.Name);
	NamesOfGroupsToCollapse.Add(Items.CollapsibleGroupQualityControl.Name);
	NamesOfGroupsToCollapse.Add(Items.CollapsibleGroupPrices.Name);
	NamesOfGroupsToCollapse.Add(Items.CollapsibleGroupTemplates.Name);
	NamesOfGroupsToCollapse.Add(Items.CollapsibleGroupOfExciseCategories.Name);

	NamesOfGroupsToCollapseLocalization(NamesOfGroupsToCollapse);
	
	Return NamesOfGroupsToCollapse;
EndFunction

&AtServerNoContext
Function UnitOfMeasure(Val PreciousMaterial)
	
	Return Common.ObjectAttributeValue(PreciousMaterial, "UnitOfMeasure");
	
EndFunction

// LongDesc
// 
// Parameters:
// 	Measure - String -
// Returns:
// 	Structure - Contains keys:
// 		* Use - String -
// 		* UnitOfMeasure - String -
// 		* Numerator - String -
// 		* Denominator - String -
// 		* CanBeSpecifiedInDocuments - String -
// 		* YouCanSpecifyStringInDocuments - String -
// 		* Indent - String -
// 		* Label - String -
&AtClientAtServerNoContext
Function MeasureProperties(Measure)
	
	MeasureProperties = New Structure;
	MeasureProperties.Insert("Use");
	MeasureProperties.Insert("UnitOfMeasure");
	MeasureProperties.Insert("Numerator");
	MeasureProperties.Insert("Denominator");
	MeasureProperties.Insert("CanBeSpecifiedInDocuments");
	MeasureProperties.Insert("YouCanSpecifyStringInDocuments");
	MeasureProperties.Insert("Indent");
	MeasureProperties.Insert("Label");
	
	If Measure = "VolumeM3" Then
		MeasureProperties.Use = "VolumeUse";
		MeasureProperties.UnitOfMeasure = "VolumeUnitOfMeasure";
		MeasureProperties.Numerator = "VolumeNumerator";
		MeasureProperties.Denominator = "VolumeDenominator";
		MeasureProperties.CanBeSpecifiedInDocuments = "VolumeCanBeSpecifiedInDocuments";
		MeasureProperties.YouCanSpecifyStringInDocuments = "YouCanSpecifyVolumeInTheDocumentsLine";
		MeasureProperties.Indent = "VolumeIndent";
		MeasureProperties.Label = "VolumeLabel";
	ElsIf Measure = "Length" Then
		MeasureProperties.Use = "LengthUse";
		MeasureProperties.UnitOfMeasure = "LengthUnitOfMeasure";
		MeasureProperties.Numerator = "LengthNumerator";
		MeasureProperties.Denominator = "LengthDenominator";
		MeasureProperties.CanBeSpecifiedInDocuments = "YouCanSpecifyLengthInDocuments";
		MeasureProperties.YouCanSpecifyStringInDocuments = "YouCanSpecifyLengthInDocumentsLine";
		MeasureProperties.Indent = "LengthIndent";
		MeasureProperties.Label = "TheLengthOfTheInscription";
	ElsIf Measure = "Width" Then
		MeasureProperties.Use = "WidthToUse";
		MeasureProperties.UnitOfMeasure = "WidthUnitOfMeasure";
		MeasureProperties.Numerator = "WidthNumerator";
		MeasureProperties.Denominator = "WidthDenominator";
		MeasureProperties.CanBeSpecifiedInDocuments = "WidthCanBeSpecifiedInDocuments";
		MeasureProperties.YouCanSpecifyStringInDocuments = "WidthCanBeSpecifiedInDocumentsLine";
		MeasureProperties.Indent = "WidthIndentation";
		MeasureProperties.Label = "WidthLabel";
	ElsIf Measure = "Weight" Then
		MeasureProperties.Use = "WeightUse";
		MeasureProperties.UnitOfMeasure = "WeightUnitOfMeasure";
		MeasureProperties.Numerator = "WeightNumerator";
		MeasureProperties.Denominator = "WeightDenominator";
		MeasureProperties.CanBeSpecifiedInDocuments = "YouCanSpecifyWeightInDocuments";
		MeasureProperties.YouCanSpecifyStringInDocuments = "YouCanSpecifyWeightInDocumentsLine";
		MeasureProperties.Indent = "WeightIndent";
		MeasureProperties.Label = "WeightLabel";
	ElsIf Measure = "AreaTypeOfMeasurement" Then
		MeasureProperties.Use = "AreaUse";
		MeasureProperties.UnitOfMeasure = "AreaUnitOfMeasure";
		MeasureProperties.Numerator = "AreaNumerator";
		MeasureProperties.Denominator = "AreaDenominator";
		MeasureProperties.CanBeSpecifiedInDocuments = "AreaCanBeSpecifiedInDocuments";
		MeasureProperties.YouCanSpecifyStringInDocuments = "YouCanSpecifyAnAreaInDocumentsLine";
		MeasureProperties.Indent = "AreaIndent";
		MeasureProperties.Label = "SquareInscription";
	Else
		Raise StrTemplate(NStr("vi = 'Chưa xác định thuộc tính phương thức %1';
								|ru = 'Не определены свойства меры %1';
								|en = 'Measure %1 properties not defined'; fa = 'Measure %1 properties not defined';
								|it = 'Proprietà di misura %1 non definite';
								|pl = 'Nie określono właściwości miary %1';
								|tr = 'Ölçü özellikleri tanımlanmamış %1'"), Measure);
	EndIf;
	
	Return MeasureProperties;
	
EndFunction

// Parameters:
//	Items - FormAllItems - form element.
//	TagName - String - name of the form elements.
//	HyperlinkName - Boolean - indicates that the name of the hyperlink form element is passed as the element name.
//
// Returns:
//	String - name of the form element.
//
&AtClientAtServerNoContext
Function NameOfLinkedListTransitionElement(Items, TagName, HyperlinkName)
	
	NewName = "";
	
	If HyperlinkName Then
		If TagName = Items.HyperlinkGoToItemPackaging.Name Then
			NewName = Items.GoToItemPackagingCommand.Name;
		ElsIf TagName = Items.HyperlinkToGoPackingSet.Name Then
			NewName = Items.GoToPackageKitCommand.Name;
		ElsIf TagName = Items.HyperlinkGoToItemCharacteristics.Name Then
			NewName = Items.GoToItemCharacteristicsCommand.Name;
		ElsIf TagName = Items.HyperlinkGoToItemWithSimilarProperties.Name Then
			NewName = Items.GoToItemWithSimilarPropertiesCommand.Name;
		ElsIf TagName = Items.HyperlinkGoToItemBarcodes.Name Then
			NewName = Items.GoToItemBarcodesCommand.Name;
		ElsIf TagName = Items.HyperlinkGoToFiles.Name Then
			NewName = Items.GoToFilesCommand.Name;
		ElsIf TagName = Items.HyperlinkGoToOtherQualityProducts.Name Then
			NewName = Items.TheTeamGoToProductsOfADifferentQuality.Name;
		ElsIf TagName = Items.HyperlinkGoToPackageConsumptionForecasts.Name Then
			NewName = Items.TheGoToPackageConsumptionForecastsCommand.Name;
		ElsIf TagName = Items.HyperlinkGoToItemPlacement.Name Then
			NewName = Items.GoToItemPlacementCommand.Name;
		ElsIf TagName = Items.HyperlinkGoToJointSales.Name Then
			NewName = Items.TheGoToJointSalesTeam.Name;
		ElsIf TagName = Items.HyperlinkGoToSegments.Name Then
			NewName = Items.GoToSegmentsCommand.Name;
		ElsIf TagName = Items.HyperlinkGoConfigurationOptions.Name Then
			NewName = Items.GoToConfigurationOptionsCommand.Name;
		ElsIf TagName = Items.HyperlinkGoSetComposition.Name Then
			NewName = Items.CommandGoSetComposition.Name;
		ElsIf TagName = Items.HyperlinkGoToInventoryMaintenanceSettings.Name Then
			NewName = Items.GoToInventoryMaintenanceSetupCommand.Name;
		ElsIf TagName = Items.HyperlinkGoSettingUpWaysToMeetYourNeeds.Name Then
			NewName = Items.TheGoCommandSetsUpWaysToMeetYourNeeds.Name;
		ElsIf TagName = Items.HyperlinkGoSettingUpTheTransferOfMaterialsToProduction.Name Then
			NewName = Items.TheGoToCommandSettingUpTheTransferOfMaterialsToProduction.Name;
		ElsIf TagName = Items.HyperlinkGoToProduction.Name Then
			NewName = Items.TheGoToProductionTeam.Name;
		ElsIf TagName = Items.HyperlinkGoToItemCertificates.Name Then
			NewName = Items.GoToItemCertificatesCommand.Name;
		ElsIf TagName = Items.HyperlinkGoDistributionOfSalesByLineOfBusiness.Name Then
			NewName = Items.TheGoTeamDistributesSalesByLineOfBusiness.Name;
		ElsIf TagName = Items.HyperlinkGoToCompanyPriceList.Name Then
			NewName = Items.TeamGoToCompanyPriceList.Name;
		ElsIf TagName = Items.HyperlinkGoToSupplierPriceLists.Name Then
			NewName = Items.CommandToChangeThePriceListsOfSuppliers.Name;
		ElsIf TagName = Items.HyperlinkGoCompanyPriceChangeHistory.Name Then
			NewName = Items.TheGoCommandIsTheHistoryOfTheCompanySPriceChanges.Name;
		ElsIf TagName = Items.HyperlinkGoSupplierPriceChangeHistory.Name Then
			NewName = Items.GoToHistoryOfSupplierPriceChangesCommand.Name;
		EndIf;
	Else
		If TagName = Items.GoToItemPackagingCommand.Name Then
			NewName = Items.HyperlinkGoToItemPackaging.Name;
		ElsIf TagName = Items.GoToPackageKitCommand.Name Then
			NewName = Items.HyperlinkToGoPackingSet.Name;
		ElsIf TagName = Items.GoToItemCharacteristicsCommand.Name Then
			NewName = Items.HyperlinkGoToItemCharacteristics.Name;
		ElsIf TagName = Items.GoToItemWithSimilarPropertiesCommand.Name Then
			NewName = Items.HyperlinkGoToItemWithSimilarProperties.Name;
		ElsIf TagName = Items.GoToItemBarcodesCommand.Name Then
			NewName = Items.HyperlinkGoToItemBarcodes.Name;
		ElsIf TagName = Items.GoToFilesCommand.Name Then
			NewName = Items.HyperlinkGoToFiles.Name;
		ElsIf TagName = Items.TheTeamGoToProductsOfADifferentQuality.Name Then
			NewName = Items.HyperlinkGoToOtherQualityProducts.Name;
		ElsIf TagName = Items.TheGoToPackageConsumptionForecastsCommand.Name Then
			NewName = Items.HyperlinkGoToPackageConsumptionForecasts.Name;
		ElsIf TagName = Items.GoToItemPlacementCommand.Name Then
			NewName = Items.HyperlinkGoToItemPlacement.Name;
		ElsIf TagName = Items.TheGoToJointSalesTeam.Name Then
			NewName = Items.HyperlinkGoToJointSales.Name;
		ElsIf TagName = Items.GoToSegmentsCommand.Name Then
			NewName = Items.HyperlinkGoToSegments.Name;
		ElsIf TagName = Items.GoToConfigurationOptionsCommand.Name Then
			NewName = Items.HyperlinkGoConfigurationOptions.Name;
		ElsIf TagName = Items.CommandGoSetComposition.Name Then
			NewName = Items.HyperlinkGoSetComposition.Name;
		ElsIf TagName = Items.GoToInventoryMaintenanceSetupCommand.Name Then
			NewName = Items.HyperlinkGoToInventoryMaintenanceSettings.Name;
		ElsIf TagName = Items.TheGoCommandSetsUpWaysToMeetYourNeeds.Name Then
			NewName = Items.HyperlinkGoSettingUpWaysToMeetYourNeeds.Name;
		ElsIf TagName = Items.TheGoToCommandSettingUpTheTransferOfMaterialsToProduction.Name Then
			NewName = Items.HyperlinkGoSettingUpTheTransferOfMaterialsToProduction.Name;
		ElsIf TagName = Items.TheGoToProductionTeam.Name Then
			NewName = Items.HyperlinkGoToProduction.Name;
		ElsIf TagName = Items.GoToItemCertificatesCommand.Name Then
			NewName = Items.HyperlinkGoToItemCertificates.Name;
		ElsIf TagName = Items.TheGoTeamDistributesSalesByLineOfBusiness.Name Then
			NewName = Items.HyperlinkGoDistributionOfSalesByLineOfBusiness.Name;
		ElsIf TagName = Items.TeamGoToCompanyPriceList.Name Then
			NewName = Items.HyperlinkGoToCompanyPriceList.Name;
		ElsIf TagName = Items.CommandToChangeThePriceListsOfSuppliers.Name Then
			NewName = Items.HyperlinkGoToSupplierPriceLists.Name;
		ElsIf TagName = Items.TheGoCommandIsTheHistoryOfTheCompanySPriceChanges.Name Then
			NewName = Items.HyperlinkGoCompanyPriceChangeHistory.Name;
		ElsIf TagName = Items.GoToHistoryOfSupplierPriceChangesCommand.Name Then
			NewName = Items.HyperlinkGoSupplierPriceChangeHistory.Name;
		EndIf;
	EndIf;
	
	Return NewName;
	
EndFunction

// Parameters:
//	Items - FormAllItems - form element.
//	TagName - String - name of the form elements.
//
// Returns:
//	Boolean - indicates that the form element is a hyperlink to the linked list.
//
&AtClientAtServerNoContext
Function JumpElementToLinkedList(Items, TagName)
	
	JumpElementToLinkedList = False;
	
	If TagName = Items.HyperlinkGoToItemPackaging.Name
		Or TagName = Items.HyperlinkToGoPackingSet.Name
		Or TagName = Items.HyperlinkGoToItemCharacteristics.Name
		Or TagName = Items.HyperlinkGoToItemWithSimilarProperties.Name
		Or TagName = Items.HyperlinkGoToItemBarcodes.Name
		Or TagName = Items.HyperlinkGoToFiles.Name
		Or TagName = Items.HyperlinkGoToOtherQualityProducts.Name
		Or TagName = Items.HyperlinkGoToPackageConsumptionForecasts.Name
		Or TagName = Items.HyperlinkGoToItemPlacement.Name
		Or TagName = Items.HyperlinkGoToJointSales.Name
		Or TagName = Items.HyperlinkGoToSegments.Name
		Or TagName = Items.HyperlinkGoToAgreements.Name
		Or TagName = Items.HyperlinkGoConfigurationOptions.Name
		Or TagName = Items.HyperlinkGoToInventoryMaintenanceSettings.Name
		Or TagName = Items.HyperlinkGoSettingUpWaysToMeetYourNeeds.Name
		Or TagName = Items.HyperlinkGoSettingUpTheTransferOfMaterialsToProduction.Name
		Or TagName = Items.HyperlinkGoToProduction.Name
		Or TagName = Items.HyperlinkGoToItemCertificates.Name
		Or TagName = Items.HyperlinkGoDistributionOfSalesByLineOfBusiness.Name
		Or TagName = Items.HyperlinkGoToCompanyPriceList.Name
		Or TagName = Items.HyperlinkGoToSupplierPriceLists.Name
		Or TagName = Items.HyperlinkGoCompanyPriceChangeHistory.Name
		Or TagName = Items.HyperlinkGoSupplierPriceChangeHistory.Name
		Or TagName = Items.HyperlinkGoSetComposition.Name
		Or TagName = Items.HyperlinkToProductVATRates.Name
		Or TagName = Items.HyperlinkGoExciseCategoriesOfItems.Name Then
		
		JumpElementToLinkedList = True
		
	EndIf;
	
	Return JumpElementToLinkedList;
	
EndFunction

&AtClient
Procedure SetStartDateOfVATRateApplicationCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		StartDateOfVATRateApplication = Undefined;
		
		Return;
	EndIf;
	
	StartDateOfVATRateApplication = Result;
	UniquenessControlBeforeWritingIsCompleted = True;
	
	Try
		ItemRecorded = Write();
	Except
		StartDateOfVATRateApplication = Undefined;
		UniquenessControlBeforeWritingIsCompleted = False;
		
		Return;
	EndTry;
	
	If Not ItemRecorded Then
		StartDateOfVATRateApplication = Undefined;
		UniquenessControlBeforeWritingIsCompleted = False;
		
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessFileEntries(EventName, Parameter, Source)
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	If Not (Object.PicturesFile.IsEmpty()
		And Object.DescriptionFileForWebsite.IsEmpty()) Then
		
		UpdateCardDescriptionFiles();
		
	Else
		CustomizeFormAndUpdateCard();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateCardDescriptionFiles()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductImages.Ref AS Ref
	|FROM
	|	Catalog.ProductsAttachedFiles AS ProductImages
	|WHERE
	|	ProductImages.Ref = &PicturesFile
	|	AND NOT ProductImages.DeletionMark
	|	AND ProductImages.FileOwner = &FileOwner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductImages.Ref AS Ref
	|FROM
	|	Catalog.ProductsAttachedFiles AS ProductImages
	|WHERE
	|	ProductImages.Ref = &DescriptionFileForWebsite
	|	AND NOT ProductImages.DeletionMark
	|	AND ProductImages.FileOwner = &FileOwner";
	
	Query.SetParameter("FileOwner",			Object.Ref);
	Query.SetParameter("PicturesFile",			Object.PicturesFile);
	Query.SetParameter("DescriptionFileForWebsite",	Object.DescriptionFileForWebsite);
	
	QueryResult = Query.ExecuteBatch();
	PictureData			= QueryResult[0];
	DescriptionDataForSite	= QueryResult[1];
	
	If Not (PictureData.IsEmpty()
		Or DescriptionDataForSite.IsEmpty()) Then
		
		Return;
		
	EndIf;
	
	If PictureData.IsEmpty() Then
		Object.PicturesFile	= Catalogs.ProductsAttachedFiles.EmptyRef();
		ImageFileData	= Undefined;
		PictureAddress		= "";
		AnErrorOccurredWhileReceivingImageData = False;
	EndIf;
	
	If DescriptionDataForSite.IsEmpty() Then
		Object.DescriptionFileForWebsite	= Catalogs.ProductsAttachedFiles.EmptyRef();
		PathToTheDescriptionFile			= "";
	EndIf;
	
	CustomizeFormAndUpdateCard();
	
EndProcedure

&AtClient
Procedure ProcessChangeOfPagesOfItemCard(CurrentPage)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Catalog.Products.ItemForm.Item.PagesProductProfile.OnCurrentPageChange",
		False,
		True);
	
	If CurrentPage = Items.ItemDetailsPage Then
		Items.GroupGroupingLeftRight.Visible = True;
	Else
		Items.GroupGroupingLeftRight.Visible = False;
		
		If Not ValueIsFilled(Object.Ref)
			Or Modified Then
			
			ClearMessages();
			
			QueryText = NStr("vi = 'Còn chưa ghi lại dữ liệu.
								|Thông tin hiển thị trên thẻ sẽ được cập nhật sau khi ghi lại.
								|Ghi lại phần tử?';
								|ru = 'Данные еще не записаны.
								|Информация, отображаемая в карточке, обновится после записи.
								|Записать элемент?';
								|en = 'Data is not recorded yet.
								|Information displayed in the profile will be updated after the data is recorded.
								|Record it?'; fa = 'Data is not recorded yet.
								|Information displayed in the profile will be updated after the data is recorded.
								|Record it?';
								|it = 'I dati non sono ancora stati registrati.
								|L''informazione visualizzata nella scheda verrà aggiornata dopo la registrazione.
								|Registrare l''elemento?';
								|pl = 'Dane jeszcze nie są zapisane. 
								|Informacja, odzwierciedlana w karcie, będzie aktualizowana po zapisaniu. 
								|Zapisać element?';
								|tr = 'Veriler henüz kaydedilmedi.
								|Kartta görüntülenen bilgiler kayıttan sonra güncellenecektir.
								|Öğeyi kaydet?'");
			
			ShowQueryBox(New CallbackDescription("PagesProductProfileOnCurrentPageChangeCompletion", ThisObject),
				QueryText,
				QuestionDialogMode.YesNo);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SwitchingItemCardPages()
	
	SystemInfo = New SystemInfo;
	
	If CommonClientServer.CompareVersions("8.3.22.1732", SystemInfo.AppVersion) > 0
		Or CommonClientServer.CompareVersions(SystemInfo.AppVersion, "8.3.22.1923") >= 0 Then
		
		Return;
		
	EndIf;
	
	ProcessChangeOfPagesOfItemCard(Items.ItemCardPage);
	ProcessChangeOfPagesOfItemCard(Items.PagesProductProfile.CurrentPage);
	
EndProcedure

// Sets the property settings for the extended hint of the classifier field.
//
// Parameters:
//	TagName - String - name of the classifier element field.
//	ClassifierData - AnyRef, String - classifier data. For the classifier code of the reference type,
//													its value is passed as a parameter, otherwise
//													the string name of the value is passed.
//
&AtServer
Procedure ConfigureClassifierFieldHint(TagName, ClassifierData)
	
	If Not Items[TagName].Visible Then
		Return;
	EndIf;
	
	DataTypeString	= TypeOf(ClassifierData) = Type("String");
	CodeIsSpecified		= ?(DataTypeString, IsBlankString(ClassifierData), ClassifierData.IsEmpty());
	
	If CodeIsSpecified Then
		Items[TagName].ToolTipRepresentation				= ToolTipRepresentation.Auto;
		Items[TagName].ExtendedTooltip.Title	= "";
	Else
		DescriptionByClassifier = ?(DataTypeString,
										ClassifierData,
										Common.ObjectAttributeValue(ClassifierData, "Description"));
		
		Items[TagName].ToolTipRepresentation				= ToolTipRepresentation.Button;
		Items[TagName].ExtendedTooltip.Title	= DescriptionByClassifier;
	EndIf;
	
EndProcedure

#EndRegion


#EndRegion

#Region Localization


&AtServer
Procedure OnCreateAtServerLocalization(Cancel, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure OnOpenLocalization(Cancel)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure BeforeCloseLocalization(Cancel, Exit, WarningText, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtServer
Procedure OnWriteAtServerLocalization(Cancel, CurrentObject, WriteParameters)
	
	
	Return;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServerLocalization(CurrentObject, WriteParameters)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure AfterWriteLocalization(WriteParameters)
	
	
	Return;
	
EndProcedure

&AtServer
Procedure NamesOfGroupsToCollapseLocalization(NamesOfGroupsToCollapse)
	
	
	Return;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceLocalization()
	

	Return;
	
EndProcedure

#Region ImportAccountingAndTraceability

&AtClientAtServerNoContext
Procedure SetAvailabilityKeepRecordsOfCCDLocalization(ItemField, Object)
	
	
	Return;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityTraceableItemLocalization(ItemField, Object)
	
	
	Return;
	
EndProcedure
&AtClientAtServerNoContext
Procedure SetTraceableItemHintLocalization(ItemField, ItemsType, ProductTypeWork)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure ProcessCommunicationLogicTraceableGoodsAndHSCodeLocalization()
	
	
	Return;
	
EndProcedure


#EndRegion


#EndRegion
