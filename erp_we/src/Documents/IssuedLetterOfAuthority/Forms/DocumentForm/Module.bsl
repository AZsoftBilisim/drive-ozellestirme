
&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var ParametersForRecording Export;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	ThereIsARightToAddDocuments = AccessRight("Update", Metadata.InformationRegisters.DocumentsPersons); 
	
	If GetFunctionalOption("BaseVersion") Then
		Items.Person.Title = NStr("vi = 'Nhân viên';
									|ru = 'Сотрудник';
									|en = 'Employee'; fa = 'کارمند';
									|it = 'Dipendente';
									|pl = 'Employee';
									|tr = 'Çalışan'");
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	If Object.AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveGoods Then
		
		StructureCharacteristicsOfProducts = New Structure;
		StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
		StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	EndIf;
	

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	SetVisibilityAvailabilityByProxyStatus();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If Object.AuthorizationLetterType = PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash") Then
		Notify("Entry_PowerOfAttorneyToReceiveCash", WriteParameters, Object.Ref);
	Else
		Notify("Entry_PowerOfAttorneyToReceiveGoods", WriteParameters, Object.Ref);
	EndIf;
	

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_DocumentIndividuals" Then
		ClearPassportData(ThisForm);
		FillOutListsOfIdentityCards();
		Object.PresentationOfPersonDocument = Parameter.Presentation;
		Object.PersonsDocumentKind = Parameter.DocumentKind;
		Object.PersonDocumentSeries = Parameter.PassportSeries;
		Object.PersonDocumentNumber = Parameter.PassportNumber_;
		Object.IssuingAuthorityOfPersonDocument = Parameter.PassportIssued;
		Object.IssueDateOfPersonDocument = Parameter.PassportDateOfIssue;
	EndIf;
	

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands


EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DocumentBasisOnChange(Item)
	
	ClearMessages();
	DocumentBasisOnChangeServer();
	
EndProcedure

&AtServer
Procedure DocumentBasisOnChangeServer()
	
	TheCurrencyOfTheDocumentBase = Undefined;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		
		Try
			
			PowerOfAttorneyObject = FormAttributeToValue("Object");
			PowerOfAttorneyObject.Fill(Object.DocumentBasis);
			PowerOfAttorneyObject.DocumentBasis = Object.DocumentBasis;
			
			ValueToFormAttribute(PowerOfAttorneyObject, "Object");
			
			If TMCommonUseClientServer.HasObjectAttribute(Object.DocumentBasis, "Currency") Then
				TheCurrencyOfTheDocumentBase = Common.ObjectAttributeValue(Object.DocumentBasis, "Currency");
			Else
				TheCurrencyOfTheDocumentBase = Object.Currency;
			EndIf;
			
		Except
			
			MessageText = NStr("vi = 'Cơ sở được chọn không chính xác: %Basis%.';
								|ru = 'Выбрано некорректное основание: %Basis%.';
								|en = 'Incorrect base is selected: %Basis%.'; fa = 'Incorrect base is selected: %Basis%.';
								|it = 'Selezionata causale errata: %Basis%.';
								|pl = 'Wybrano nieprawidłową podstawę: %Basis%.';
								|tr = 'Yanlış tabanlar seçilmiştir: %Basis%.'");
			MessageText = StrReplace(MessageText, "%Basis%", Object.DocumentBasis);
			
			Common.MessageToUser(MessageText);
			
			Object.DocumentBasis = Undefined;
			
		EndTry;
		
	EndIf;
	
	If Object.AuthorizationLetterType = PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveGoods") Then
		Object.Currency = Undefined;
		Object.DocumentAmount = 0;
		
		Object.TangibleAssets.Clear();
	ElsIf Object.AuthorizationLetterType = PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash") Then
		Object.Currency = TheCurrencyOfTheDocumentBase;
		
		Object.Goods.Clear();
		Object.TangibleAssets.Clear();
	Else
		Object.Currency = Undefined;
		Object.DocumentAmount = 0;
		
		Object.Goods.Clear();
	EndIf;
	
	Items.Currency.ReadOnly = ValueIsFilled(Object.DocumentBasis);
	
	SetVisibilityByProxyType();
	
EndProcedure

&AtClient
Procedure AuthorizationLetterTypeOnChange(Item)
	
	If Not ValueIsFilled(Object.AuthorizationLetterType) Then
		Object.AuthorizationLetterType = AuthorizationLetterType(Object);
	EndIf;
	
	If Object.AuthorizationLetterType = PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveGoods")
		Or Object.AuthorizationLetterType = PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveOtherMaterials") Then
		
		Object.Currency = Undefined;
		Object.DocumentAmount = 0;
		
		If Object.AuthorizationLetterType = PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveGoods") Then
			Object.TangibleAssets.Clear();
		Else
			Object.Goods.Clear();
		EndIf;
		
	ElsIf Object.AuthorizationLetterType = PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash") Then
		
		Object.Currency = TheCurrencyOfTheDocumentBase;
		
		Object.Goods.Clear();
		Object.TangibleAssets.Clear();
		
	EndIf;
	
	TypesOfBases_ = TypesOfBases_(Object.AuthorizationLetterType);
	
	If ValueIsFilled(Object.DocumentBasis)
		And TypesOfBases_.Find(TypeOf(Object.DocumentBasis)) = Undefined Then
		
		Object.DocumentBasis = Undefined;
		
	EndIf;
	
	SetVisibilityByProxyType();
	
EndProcedure

&AtClient
Procedure PersonOnChange(Item)
	
	If ValueIsFilled(Object.Person) Then
		WhenChangingPhysicalServer();
	Else
		Items.JobTitle.ChoiceList.Clear();
		Items.IdentificationCard.ChoiceList.Clear();
		JobListIsLoaded = True;
		Object.PresentationOfPersonDocument = "";
		ClearPassportData(ThisForm);
	EndIf;
EndProcedure

&AtClient
Procedure ValidityPeriodOnChange(Item)
	
	Object.ValidityEndDate = CalculateExpirationDate(BegOfDay(Object.Date), Object.ValidityPeriod);
EndProcedure

&AtClient
Procedure ValidityEndDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Object.ValidityPeriod = CalculateValidityPeriod(Object.Date, Object.ValidityEndDate);
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
EndProcedure

&AtClient
Procedure PartnerOnChange(Item) 
	
	If Not ValueIsFilled (Object.Partner) Then
		Return;
	EndIf;
	WhenChangingPartnerServer();
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
EndProcedure

&AtClient
Procedure IdentificationCardChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected = Undefined Then
		StandardProcessing = False;
		
		FormParameters = New Structure();
		FormParameters.Insert("Person", Object.Person);
		OpenForm("InformationRegister.DocumentsPersons.RecordForm", FormParameters, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		FilterParameters = New Structure;
		FilterParameters.Insert("PresentationOfPersonDocument", ValueSelected);
		FoundRows = DocumentsList.FindRows(FilterParameters);
		If FoundRows.Count()>0 Then
			FoundDocument = FoundRows.Get(0);
			FillPropertyValues(Object, FoundDocument);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure IdentificationCardClearing(Item, StandardProcessing)
	
	ClearPassportData(ThisForm);
EndProcedure

&AtClient
Procedure IdentificationCardAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	
	StandardProcessing = False;
	PickingParameters = New Structure("SearchString, Person");
	PickingParameters.SearchString = Text;
	PickingParameters.Person = Object.Person;
	ChoiceData = GetDocumentSelectionData(PickingParameters);
	If ThereIsARightToAddDocuments Then
		ChoiceData.Insert(0,Undefined, NStr("vi = '<Tạo mới>';
											|ru = '<Создать новый>';
											|en = '<Create new>'; fa = '<Create new>';
											|it = '<Creare un nuovo>';
											|pl = '<Utwórz nowy>';
											|tr = '<Yenisini oluştur>'"));
	EndIf;
EndProcedure

&AtClient
Procedure IdentificationCardTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		StandardProcessing = False;
		PickingParameters = New Structure("SearchString, Person");
		PickingParameters.SearchString = Text;
		PickingParameters.Person = Object.Person;
		ChoiceData = GetDocumentSelectionData(PickingParameters);
		If ThereIsARightToAddDocuments Then
			ChoiceData.Insert(0,Undefined, NStr("vi = '<Tạo mới>';
												|ru = '<Создать новый>';
												|en = '<Create new>'; fa = '<Create new>';
												|it = '<Creare un nuovo>';
												|pl = '<Utwórz nowy>';
												|tr = '<Yenisini oluştur>'"));
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	StatusChangedOnServer();
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "GoodsPartnerProducts", NStr("vi = 'Nhà cung cấp';
																									|ru = 'Поставщик';
																									|en = 'Vendor'; fa = 'تأمین‌کننده';
																									|it = 'Fornitore';
																									|pl = 'Dostawca';
																									|tr = 'Tedarikçi'"));

EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return
	ElsIf Item.CurrentItem.Name = "GoodsPartnerProducts" Then
		If YouHaveAccessToTheSupplierSNomenclature Then
			
			CurrentData = Items.Goods.CurrentData;

			PartnersProductsClient.FillInPartnerProductSelectionList(
				Object.Partner, CurrentData, Items.GoodsPartnerProducts.ChoiceList);

			PartnersProductsClient.SetPackageSelectionParameters(
				Items.GoodsPartnerProducts.ChoiceParameters, CurrentData);
		
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure ShowSupplierProducts(Command)
	
	PartnersProductsClient.ShowThePartnerSNomenclature(Object.Partner, Object.Ref, Items.Goods.CurrentData, NStr("vi = 'Nhà cung cấp';
																												|ru = 'Поставщик';
																												|en = 'Vendor'; fa = 'تأمین‌کننده';
																												|it = 'Fornitore';
																												|pl = 'Dostawca';
																												|tr = 'Tedarikçi'"));
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable);
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItem(Command)
	
	If Not TMCommonUseClient.CheckForRowsInList(Object.Goods, "Goods") Then
		Return;
	EndIf;
	
	GoodsAddressInStorage = PlaceGoodsInTemporaryStorageServer();
	PurchasesClient.OpenSupplierProductListForm(
		New CallbackDescription("FillInTheItemByThePartnerSItemCompletion", ThisObject),
		GoodsAddressInStorage,
		ThisForm);
		
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItemCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		FillInItemsFromTemporaryStorageServer(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInCashDS(Command)
	
	If Not ValueIsFilled(Object.DocumentBasis) Then
		ClearMessages();
		Message = NStr("vi = 'Chỉ ra cơ sở cho việc tính toán.';
						|ru = 'Укажите основание для заполнения по расчетам.';
						|en = 'Specify the base document for population by settlements.'; fa = 'Specify the base document for population by settlements.';
						|it = 'Specificare la causale per la compilazione in base ai calcoli.';
						|pl = 'Wskaź podstawę do wypełnienia według rozliczeń.';
						|tr = 'Hesaplamayı doldurmak için tabanı belirtin.'");
		CommonClientServer.MessageToUser(Message,, "Object.DocumentBasis");
		Return;
	EndIf;
	
	If Not Object.DocumentAmount = 0 Then
		QueryText = StrTemplate(NStr("vi = 'Số tiền cần nhận theo giấy ủy quyền
		|sẽ được điền lại khi tính toán trên cơ sở %1. Tiếp tục?';
		|ru = 'Сумма к получению по доверенности
		|будет перезаполнена по расчетам по основанию %1. Продолжить?';
		|en = 'The amount to receive under the authorization letter will be overwritten according to settlements by base document %1.
		|Continue?'; fa = 'The amount to receive under the authorization letter will be overwritten according to settlements by base document %1.
		|Continue?';
		|it = 'L''importo da incassare per delega
		| sarà ricompilato secondo i calcoli in base alla causale %1. Continuare?';
		|pl = 'Wartość do otrzymania na podstawie pełnomocnictwa 
		|będzie ponownie wypełniona według rozliczeń na podstawie %1. Kontynuować?';
		|tr = 'Vekaleten alacak tutarı,
		| vekaletname bazında yapılan hesaplama ile üzerine yazılacaktır.%1 Devam edilsin mi?'"), TrimAll(Object.DocumentBasis));
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Continue';
													|tr = 'Devam'"));
		ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
		Response = Undefined;
		
		ShowQueryBox(New CallbackDescription("FillInCashDSCompletion", ThisObject),
			QueryText, ButtonsList,, DialogReturnCode.Yes, NStr("vi = 'Điền số tiền cần nhận';
																|ru = 'Заполнение суммы к получению';
																|en = 'Filling in the amount due'; fa = 'Filling in the amount due';
																|it = 'Compilazione dell''importo da incassare';
																|pl = 'Wypełnienie wartości do otrzymania';
																|tr = 'Alacak miktarının doldurulması'"));
		Return;
	EndIf;
	FillInCashCashFragment();
EndProcedure

&AtClient
Procedure FillInCashDSCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FillInCashCashFragment();
EndProcedure

&AtClient
Procedure FillInCashCashFragment()
	
	Var MessageText;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		FillInCashCashOnServer();
	EndIf;
	
	If Object.DocumentAmount = 0 Then
		MessageText = StrTemplate(NStr("vi = 'Không có khoản nợ nào thanh toántrên cơ sở %1';
										|ru = 'Отсутствует задолженность по расчетам по основанию %1';
										|en = 'No debt for settlements by base document %1'; fa = 'No debt for settlements by base document %1';
										|it = 'Nessun arretrato secondo i calcoli in base alla causale %1';
										|pl = 'Brak zobowiązania według rozliczeń na podstawie %1';
										|tr = '%1temelinde ödemelerde ödenmemiş borç yoktur '"),
			TrimAll(Object.DocumentBasis));
		ShowMessageBox(Undefined, MessageText);
	EndIf;
EndProcedure

&AtClient
Procedure FillInUsingBaseDocument(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.DocumentBasis) Then
		MessageText = NStr("vi = 'Các cơ sở không được điền.';
							|ru = 'Не заполнено основание.';
							|en = 'The base is not filled in.'; fa = 'The base is not filled in.';
							|it = 'Causale non compilata.';
							|pl = 'Nie wypełniono podstawy.';
							|tr = 'Taban doldurulmamıştır.'");
		
		CommonClient.MessageToUser(MessageText);
		
		Return;
	EndIf;
	
	If Object.Goods.Count() > 0 Then
		
		CallbackDescription = New CallbackDescription("FillInUsingBaseDocumentCompletion", ThisObject);
		
		QueryText = NStr("vi = 'Danh sách hàng hóa cần nhận giấy ủy quyền sẽ được điền lại theo chứng từ cơ sở. Tiếp tục?';
						|ru = 'Список товаров к получению по доверенности будет перезаполнен по основанию. Продолжить?';
						|en = 'The list of goods to receive under the authorization letter will be repopulated using the ""Input on basis"" method. Continue?'; fa = 'The list of goods to receive under the authorization letter will be repopulated using the ""Input on basis"" method. Continue?';
						|it = 'L''elenco delle merci da ricevere per delega sarà ricompilato in base alla causale. Continuare?';
						|pl = 'Lista towarów do otrzymania według pełnomocnictwa będzie wypełniony ponownie na podstawie. Kontynuować?';
						|tr = 'Vekaleten alınacak malların listesi gerekçe ile üzerine yazılacaktır. Devam edilsin mi?'");
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Continue';
													|tr = 'Devam'"));
		ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
		
		TitleOfQuestionWindow = NStr("vi = 'Điền số tiền cần nhận';
									|ru = 'Заполнение товаров к получению';
									|en = 'Filling in the goods to be received'; fa = 'Filling in the goods to be received';
									|it = 'Compilazione delle merci da ricevere';
									|pl = 'Wypełnienie towarów do otrzymania';
									|tr = 'Alınacak malların doldurulması'");
		
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList, , DialogReturnCode.Yes, TitleOfQuestionWindow);
		
		Return;
		
	EndIf;
	
	FillInUsingBaseDocumentServer();
	
EndProcedure

&AtClient
Procedure FillInUsingBaseDocumentCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FillInUsingBaseDocumentServer();
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure CalculateStatus(Command)
	
	Handler = New CallbackDescription("ProceedRunningCommandAfterRecordConfirmed", ThisObject);
	
	If Object.Ref.IsEmpty() Or Modified Then
		QueryText = NStr("vi = 'Chứng từ vẫn chưa được ghi lại.
		|Chỉ có thể tính toán trạng thái sau khi ghi lại dữ liệu.
		|Dữ liệu sẽ được ghi lại.';
		|ru = 'Документ еще не записан.
		|Рассчитать статус возможно только после записи данных.
		|Данные будут записаны.';
		|en = 'Document is not saved yet.
		|Status can be calculated only after data is saved.
		|Data will be saved.'; fa = 'Document is not saved yet.
		|Status can be calculated only after data is saved.
		|Data will be saved.';
		|it = 'Il documento non è ancora stato registrato.
		|Lo stato può essere calcolato solo dopo la registrazione dei dati.
		|I dati verranno registrati.';
		|pl = 'Dokument jeszcze nie jest zapisany.
		|Rozliczenie statusu jest możliwe tylko po zapisaniu danych.
		|Dane zostaną zapisane.';
		|tr = 'Belge henüz kaydedilmemiştir.
		| Durumu hesaplamak ancak veriler yazıldıktan sonra mümkündür.
		|Veriler kaydedilecektir.'");
		
		ShowQueryBox(Handler, QueryText, QuestionDialogMode.OKCancel);
	Else
		RunCallback(Handler, DialogReturnCode.OK);
	EndIf;
EndProcedure

&AtClient
Procedure ProceedRunningCommandAfterRecordConfirmed(Val Response = Undefined, Val AdditionalParameters = Undefined) Export
	
	If Response = Undefined Or Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Response = DialogReturnCode.OK Then
		ClearMessages();
		Write();
		If Object.Ref.IsEmpty() Or Modified Then
			Return;
		EndIf;
	EndIf;
	CurrentStatus = Object.Status;
	CurOfPayments = Object.DocumentPaymentsAmount;
	CurReceiptOfGoods = Object.HasGoodsReceipt;
	CalculateStateOnServer();
	If Not CurrentStatus = Object.Status
		Or Not CurOfPayments = Object.DocumentPaymentsAmount
		Or Not CurReceiptOfGoods = Object.HasGoodsReceipt Then
		Modified = True;
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "GoodsUnitOfMeasure";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
		
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPartnerProducts.Name);
		
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn nhà cung cấp>';
													|ru = '<выберите поставщика>';
													|en = '<select vendor>'; fa = '<select vendor>';
													|it = '<selezionare il fornitore>';
													|pl = '<wybierz dostawcę>';
													|tr = '<tedarikçi seçin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
		
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WhenChangingPhysicalServer()
	
	ArrayOfEmployeePositions = EmployeePositions(Object.Person);
	If ArrayOfEmployeePositions.Count() > 0 Then
		Object.JobTitle = ArrayOfEmployeePositions[0];
	EndIf;
	Items.IdentificationCard.ChoiceList.Clear();
	GetLatestPassportDataAs();
	FillJobSelectionList();
	FillOutListsOfIdentityCards();
EndProcedure

&AtServer
Procedure WhenChangingPartnerServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Goods, Object.Partner);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	Object.BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		Object.BankAccount);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
EndProcedure

#EndRegion

#Region LetterOfAuthorityStatus

&AtServer
Procedure CalculateStateOnServer()
	
	If Not (Object.Status = Enums.StatusesOfAuthorizationLetters.Issued
			Or Object.Status = Enums.StatusesOfAuthorizationLetters.UsedPartially) Then
		Return;
	EndIf;
	
	ObjectsArray = New Array();
	ObjectsArray.Add(Object.Ref);
	
	StateTable_ = Documents.IssuedLetterOfAuthority.CalculateStateOfPowerOfAttorney(ObjectsArray);
	
	If StateTable_.Count() = 0 Then
		Return;
	EndIf;
	
	Documents.IssuedLetterOfAuthority.CalculatePowerOfAttorneyStatus(Object,
		StateTable_[0].ThereArePayments, StateTable_[0].AmountOfPayments, StateTable_[0].HasGoodsReceipt);
		
	SetStateOfPowerOfAttorney();
	StatusChangedOnServer();
EndProcedure

&AtServer
Procedure SetStateOfPowerOfAttorney()
	
	LetterOfAuthorityStatus = "";
	If Object.Status = Enums.StatusesOfAuthorizationLetters.NotIssued Then
		Return;
	EndIf;
	
	If Object.AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveOtherMaterials Then
		Return;
	EndIf;
	
	TextNoReceiptOfTheDS = NStr("vi = 'Không thu tiền';
								|ru = 'Нет поступления ДС';
								|en = 'No cash receipt'; fa = 'No cash receipt';
								|it = 'Nessun entrata di fondi monetari';
								|pl = 'Brak wpłaty środków pieniężnych';
								|tr = 'Nakit makbuzu yok'");
	TextNoGoodsReceived = NStr("vi = 'Không tiếp nhận hàng hóa';
								|ru = 'Нет поступления товаров (МЦ)';
								|en = 'No goods receipt (tangible assets)'; fa = 'No goods receipt (tangible assets)';
								|it = 'Nessun entrata delle merci (beni e materiali)';
								|pl = 'Brak wpływu towarów (wartości materialnych)';
								|tr = 'Mal makbuzu yok (envanter)'");
	TheTextIsTheReceiptOfGoods = NStr("vi = 'Có tiếp nhận hàng hóa';
										|ru = 'Есть поступления товаров (МЦ)';
										|en = 'There are goods receipts (tangible assets)'; fa = 'There are goods receipts (tangible assets)';
										|it = 'Ci sono gli arrivi delle merci (beni e materiali)';
										|pl = 'Są wpływy towarów (wartości materialnych)';
										|tr = 'Mal makbuzu mevcut (envanter)'");
	TextFullReceiptOfTheDS = NStr("vi = 'Đã thu tiền đầy đủ';
									|ru = 'ДС поступили полностью';
									|en = 'Cash received in full'; fa = 'Cash received in full';
									|it = 'I fondi monetari entrati completamente';
									|pl = 'Środki pieniężne wpłyneły w całości';
									|tr = 'Nakit tam olarak alındı'");
	TextPartialReceiptOfDS = NStr("vi = 'Đã thu một phần: %1';
									|ru = 'ДС поступили частично: %1';
									|en = 'Cash partially received: %1'; fa = 'Cash partially received: %1';
									|it = 'I fondi monetari entrati parzialmente: %1';
									|pl = 'Środki pieniężne wpłyneły częściowo: %1';
									|tr = 'Nakit kısmen alındı: %1'");
	
	If Object.AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveCash Then
		If Object.DocumentPaymentsAmount = 0 Then
			LetterOfAuthorityStatus = TextNoReceiptOfTheDS;
		Else
			If Object.DocumentPaymentsAmount < Object.DocumentAmount Then
				LetterOfAuthorityStatus = StrTemplate(TextPartialReceiptOfDS,
				Format(Object.DocumentPaymentsAmount, "NFD=2; NGS="));
			Else
				LetterOfAuthorityStatus = TextFullReceiptOfTheDS;
			EndIf;
		EndIf;
	Else
		If Object.HasGoodsReceipt Then
			LetterOfAuthorityStatus = TheTextIsTheReceiptOfGoods;
		Else
			LetterOfAuthorityStatus = TextNoGoodsReceived;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure StatusChangedOnServer()
	
	IssuedUsed = Not Object.Status = Enums.StatusesOfAuthorizationLetters.NotIssued;
	Items.Pages.ReadOnly = IssuedUsed;
	Items.AuthorizationLetterType.ReadOnly = IssuedUsed;
	Items.FillInCashDS.Enabled = Not IssuedUsed;
	Items.GoodsSplitRow.Enabled = Not IssuedUsed;
	Items.GoodsFillInUsingBaseDocument.Enabled = Not IssuedUsed;
	Items.GoodsFillInTheItemByThePartnerSItem.Enabled = Not IssuedUsed;
	
	CalculationAvailability = False;
	
	If Object.AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveGoods Then
		CalculationAvailability = Object.Status = Enums.StatusesOfAuthorizationLetters.Issued;
	ElsIf Object.AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveCash Then
		CalculationAvailability = Object.Status = Enums.StatusesOfAuthorizationLetters.Issued
			Or Object.Status = Enums.StatusesOfAuthorizationLetters.UsedPartially;
	EndIf;
		
	Items.CalculateStatus.Enabled = CalculationAvailability;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	SetVisibilityByProxyType();
	FillJobSelectionList();
	FillOutListsOfIdentityCards();
	If Object.AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveGoods Then
		
		StructureCharacteristicsOfProducts = New Structure;
		StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
		StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	EndIf;
	SetVisibilityAvailabilityByProxyStatus();
	If ValueIsFilled(Object.DocumentBasis) Then
		SetPrivilegedMode(True);
		If TMCommonUseClientServer.HasObjectAttribute(Object.DocumentBasis, "Currency") Then
			TheCurrencyOfTheDocumentBase = Common.ObjectAttributeValue(Object.DocumentBasis, "Currency");
		Else
			TheCurrencyOfTheDocumentBase = Object.Currency;
		EndIf;
	EndIf;
	Items.Currency.ReadOnly = ValueIsFilled(Object.DocumentBasis);
	
	SetStateOfPowerOfAttorney();
	StatusChangedOnServer();
EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityByProxyStatus()
	
	HasEditPermission = AccessRight("Update", Metadata.Documents.IssuedLetterOfAuthority);
	StatusAvailable = UserRightsCached.WriteIssuedAuthorizationLetterInItsFinalStatus();
	IssuedLetterOfAuthority = Not Object.Status = Enums.StatusesOfAuthorizationLetters.NotIssued;
	ReadOnly = (IssuedLetterOfAuthority And Not StatusAvailable)
						Or Object.DeletionMark
						Or Not HasEditPermission;
	
	Items.Status.Enabled = StatusAvailable;
	
	If IssuedLetterOfAuthority Then
		StatusNotIssued = Items.Status.ChoiceList.FindByValue(Enums.StatusesOfAuthorizationLetters.NotIssued);
		If Not StatusNotIssued = Undefined Then
			Items.Status.ChoiceList.Delete(StatusNotIssued);
		EndIf;
		Items.DocumentBasis.Visible = True;
		Items.DocumentBasis1.Visible = False;
	Else
		Items.DocumentBasis.Visible = False;
		Items.DocumentBasis1.Visible = True;
	EndIf;
	
	Items.EmployeeResponsible.Visible = IssuedLetterOfAuthority;
	
	YouHaveAccessToTheSupplierSNomenclature = AccessRight("Read", Metadata.Catalogs.ProductCrossReferences);
	Items.GoodsFillInTheItemByThePartnerSItem.Visible = YouHaveAccessToTheSupplierSNomenclature;
	Items.GoodsPartnerProducts.ReadOnly = Not YouHaveAccessToTheSupplierSNomenclature;
	
EndProcedure

&AtServerNoContext
Function EmployeePositions(Person)
	
	Query = New Query("SELECT ALLOWED DISTINCT
	|	LetterOfAuthority.JobTitle AS JobTitle,
	|	MAX(LetterOfAuthority.Date) AS Date
	|FROM
	|	Document.IssuedLetterOfAuthority AS LetterOfAuthority
	|WHERE
	|	LetterOfAuthority.Person = &Person
	|	AND LetterOfAuthority.JobTitle <> """"
	|	AND NOT LetterOfAuthority.DeletionMark
	|
	|GROUP BY
	|	LetterOfAuthority.JobTitle
	|
	|ORDER BY
	|	Date DESC");
	Query.SetParameter("Person", Person);
	QueryResult = Query.Execute();
	Return QueryResult.Unload().UnloadColumn("JobTitle");
	
EndFunction

&AtServerNoContext
Function CalculateExpirationDate(ValidityStartDate, ValidityPeriod)
	
	ValidityEndDate = Date(1,1,1);
	If ValueIsFilled(ValidityStartDate) Then
		If ValidityPeriod > 0 Then
			MainEnterpriseCalendar = Constants.MainEnterpriseCalendar.Get();
			If ValueIsFilled(MainEnterpriseCalendar) Then
				ValidityEndDate = 
					CalendarSchedules.DateByCalendar(MainEnterpriseCalendar, ValidityStartDate, ValidityPeriod);
			Else
				ValidityEndDate = ValidityStartDate + ValidityPeriod * 86400;
			EndIf;
			Return ValidityEndDate;
		EndIf;
	EndIf;
EndFunction

&AtServerNoContext
Function CalculateValidityPeriod(ValidityStartDate, ValidityEndDate)
	
	ValidityPeriod = 0;
	If ValueIsFilled(ValidityEndDate) And ValidityEndDate >= ValidityStartDate Then
		MainEnterpriseCalendar = Constants.MainEnterpriseCalendar.Get();
		If ValueIsFilled(MainEnterpriseCalendar) Then
			Try
				ValidityPeriod = CalendarSchedules.DateDiffByCalendar(MainEnterpriseCalendar, ValidityStartDate, ValidityEndDate);
			Except
				ValidityPeriod = 0;
			EndTry;
		Else
			ValidityPeriod = (BegOfDay(ValidityEndDate) - BegOfDay(ValidityStartDate)) / 86400;
		EndIf;
	EndIf;
	Return ValidityPeriod;
EndFunction

&AtServer
Function PlaceGoodsInTemporaryStorageServer()
	
	Return PurchasesServer.PlaceGoodsInTemporaryStorage(Object.Goods);
EndFunction

&AtServer
Procedure FillInItemsFromTemporaryStorageServer(AddressInTempStorage)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);

	TableOfGoods = GetFromTempStorage(AddressInTempStorage); // DocumentTabularSection.IssuedLetterOfAuthority.Goods
	RowsToProcess = New Array;
	
	For Each CurRow In TableOfGoods Do
		ArrayOfCollectionRows = Object.Goods.FindRows(New Structure("LineNumber", CurRow.LineNumber));
		If ArrayOfCollectionRows.Count() <> 1 Then
			Continue;
		Else
			CollectionRow = ArrayOfCollectionRows[0];
		EndIf;
		FillPropertyValues(CollectionRow, CurRow, "Products, Characteristic, Package");
		RowsToProcess.Add(CollectionRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
EndProcedure

&AtServer
Procedure GetLatestPassportDataAs()
	
	DocumentOfTheIndividual = PersonsTM.GetIndividualSDefaultDocument(Object.Person);
	
	Object.PersonsDocumentKind = DocumentOfTheIndividual.DocumentKind;
	Object.PersonDocumentSeries = DocumentOfTheIndividual.Series;
	Object.PersonDocumentNumber = DocumentOfTheIndividual.Number;
	Object.IssuingAuthorityOfPersonDocument = DocumentOfTheIndividual.IssuedBy;
	Object.IssueDateOfPersonDocument = DocumentOfTheIndividual.DateOfIssue1;
	Object.PresentationOfPersonDocument = DocumentOfTheIndividual.Presentation;
	
EndProcedure

&AtServer
Procedure FillOutListsOfIdentityCards()
	
	Items.IdentificationCard.ChoiceList.Clear();
	DocumentsList.Clear();
	DocumentsList.Load(DocumentsOfLegalEntity(Items.IdentificationCard,Object.Person));
	For Each Document In DocumentsList Do
		Items.IdentificationCard.ChoiceList.Add(Document.PresentationOfPersonDocument,
			Document.PresentationOfPersonDocument);
	EndDo; 
EndProcedure

&AtServer
Function DocumentsOfLegalEntity(IdentityCardElement, Person)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DocumentsPersonsSliceLast.DocumentKind AS PersonsDocumentKind,
	|	DocumentsPersonsSliceLast.Series AS PersonDocumentSeries,
	|	DocumentsPersonsSliceLast.Number AS PersonDocumentNumber,
	|	DocumentsPersonsSliceLast.IssuedBy AS IssuingAuthorityOfPersonDocument,
	|	DocumentsPersonsSliceLast.DateOfIssue1 AS IssueDateOfPersonDocument,
	|	DocumentsPersonsSliceLast.Presentation AS PresentationOfPersonDocument
	|FROM
	|	InformationRegister.DocumentsPersons.SliceLast AS DocumentsPersonsSliceLast
	|WHERE
	|	DocumentsPersonsSliceLast.Person = &Person
	|	AND DocumentsPersonsSliceLast.ThisIsAnIdentityDocument
	|
	|ORDER BY
	|	IssueDateOfPersonDocument DESC";
	Query.SetParameter("Person", Person);
	Result = Query.Execute();
	SelectionDetailRecords = Result.Select();
	TableOfDocumentsOfLegalEntity = New ValueTable;
	TableOfDocumentsOfLegalEntity.Columns.Add("PersonsDocumentKind",
		New TypeDescription("CatalogRef.DocumentKindsOfPersons"));
	TableOfDocumentsOfLegalEntity.Columns.Add("PersonDocumentSeries", New TypeDescription("String"));
	TableOfDocumentsOfLegalEntity.Columns.Add("PersonDocumentNumber", New TypeDescription("String"));
	TableOfDocumentsOfLegalEntity.Columns.Add("IssuingAuthorityOfPersonDocument", New TypeDescription("String"));
	TableOfDocumentsOfLegalEntity.Columns.Add("IssueDateOfPersonDocument", New TypeDescription("Date"));
	TableOfDocumentsOfLegalEntity.Columns.Add("PresentationOfPersonDocument", New TypeDescription("String"));
	While SelectionDetailRecords.Next() Do
		NewDocument = TableOfDocumentsOfLegalEntity.Add();
		FillPropertyValues(NewDocument,SelectionDetailRecords);
	EndDo;
	Return TableOfDocumentsOfLegalEntity;
EndFunction

&AtClientAtServerNoContext
Procedure ClearPassportData(Form)
	
	Form.Object.PersonsDocumentKind = PredefinedValue("Catalog.DocumentKindsOfPersons.EmptyRef");
	Form.Object.IssuingAuthorityOfPersonDocument = "";
	Form.Object.IssueDateOfPersonDocument = "";
	Form.Object.PersonDocumentNumber = "";
	Form.Object.PresentationOfPersonDocument = "";
	Form.Object.PersonDocumentSeries = "";
EndProcedure

&AtServerNoContext
Function GetDocumentSelectionData(Parameters)
	
	ChoiceData = New ValueList;
	If ValueIsFilled(Parameters.SearchString) Then
		Query = New Query;
		Query.Text = 
			"SELECT
			|	DocumentsPersonsSliceLast.Presentation AS PresentationOfDocument
			|FROM
			|	InformationRegister.DocumentsPersons.SliceLast AS DocumentsPersonsSliceLast
			|WHERE
			|	DocumentsPersonsSliceLast.Person = &Person
			|	AND DocumentsPersonsSliceLast.ThisIsAnIdentityDocument
			|	AND DocumentsPersonsSliceLast.Presentation LIKE &SearchString";
		Query.SetParameter("Person", Parameters.Person);
		Query.SetParameter("SearchString","%" + TrimAll(Parameters.SearchString) + "%");
		Result = Query.Execute();
		SelectionDetailRecords = Result.Select();
		While SelectionDetailRecords.Next() Do
			ChoiceData.Add(SelectionDetailRecords.PresentationOfDocument,SelectionDetailRecords.PresentationOfDocument);
		EndDo;
	EndIf;
	Return ChoiceData;
EndFunction

&AtServer
Procedure FillJobSelectionList()
	
	If Not JobListIsLoaded And ValueIsFilled(Object.Person) Then
		ArrayOfEmployeePositions = EmployeePositions(Object.Person);
		Items.JobTitle.ChoiceList.Clear();
		For Each EmployeePosition In ArrayOfEmployeePositions Do
			Items.JobTitle.ChoiceList.Add(EmployeePosition);
		EndDo;
		JobListIsLoaded = True;
	EndIf;
EndProcedure


&AtServer
Procedure FillInCashCashOnServer()
	
	GoodsSales = Object.DocumentBasis;
	ARAPDetails = Documents.IssuedLetterOfAuthority.GetPaymentDecryptionTable();
	
	If Not TypeOf(GoodsSales) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
		
		If TypeOf(GoodsSales) = Type("DocumentRef.CustomerInvoice") Then
			Query = New Query("
			|SELECT DISTINCT
			|	GoodsTable.SalesOrder AS SalesOrder
			|FROM
			|	Document.CustomerInvoice.Goods AS GoodsTable
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND GoodsTable.Ref.OrderSales
			|");
			Query.SetParameter("Ref", GoodsSales);
			SetPrivilegedMode(True);
			RequestResultForOrders = Query.Execute();
			SetPrivilegedMode(False);
			If Not RequestResultForOrders.IsEmpty() Then
				CustomerOrders = RequestResultForOrders.Unload().UnloadColumn("SalesOrder");
				CustomerOrders.Add(GoodsSales);
			Else
				CustomerOrders = GoodsSales;
			EndIf;
		Else
			CustomerOrders = GoodsSales;
		EndIf;
		If TypeOf(Object.DocumentBasis) = Type("CatalogRef.CounterpartyContracts") Then
			DetailsOfFoundation = New Structure("Contract, Currency", Object.DocumentBasis, Object.Currency);
		Else
			SetPrivilegedMode(True);
			DetailsOfFoundation = Common.ObjectAttributesValues(GoodsSales, "Contract, Currency");
			SetPrivilegedMode(False);
		EndIf;
		
		ParametersForFillingInDecryption = ARAPAccountingARAPDetailsFillingIn.ParametersForFillingInOrderPaymentDecryption();
		ParametersForFillingInDecryption.SalesOrder     = CustomerOrders;
		ParametersForFillingInDecryption.Contract          = DetailsOfFoundation.Contract;
		ParametersForFillingInDecryption.DocumentCurrency  = DetailsOfFoundation.Currency;
		ParametersForFillingInDecryption.Partner          = Object.Partner;
		ParametersForFillingInDecryption.PaymentPurpose = GoodsSales;
		
		ARAPAccountingARAPDetailsFillingIn.FillInTranscriptOfPaymentOnClientSOrder(
			ParametersForFillingInDecryption,
			ARAPDetails);
		
		Object.DocumentAmount = ARAPDetails.Total("Sum");
		Object.Currency = DetailsOfFoundation.Currency;
	Else
		SetPrivilegedMode(True);
		DetailsOfFoundation = Common.ObjectAttributesValues(GoodsSales, "CompensationMethod, Contract, Currency, DocumentAmount, Organization");
		SetPrivilegedMode(False);
		
		If DetailsOfFoundation.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ReturnCash Then
			ARAPObject = GoodsSales;
		Else
			ARAPObject = DetailsOfFoundation.Contract;
		EndIf;
		
		Query = New Query("
		|SELECT
		|	VendorsARAPAccounting.Currency AS ARAPCurrency,
		|	VendorsARAPAccounting.SumBalance AS AmountARAP
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(,
		|		ARAPObject.Object = &ARAPObject
		|	) AS VendorsARAPAccounting
		|WHERE
		|	VendorsARAPAccounting.SumBalance > 0
		|");
		Query.SetParameter("ARAPObject", ARAPObject);
		SampleByCalculation = Query.Execute().Select();
		If SampleByCalculation.Next() Then
			NewRow = ARAPDetails.Add();
			FillPropertyValues(NewRow, SampleByCalculation);
			Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(DetailsOfFoundation.Currency,
			SampleByCalculation.ARAPCurrency, CurrentSessionDate(), DetailsOfFoundation.Organization);
			LineAmount_ = ?(Coefficients.ConversionRateToSettlementCurrency <> 0,
			NewRow.AmountARAP / Coefficients.ConversionRateToSettlementCurrency, 0);
			If LineAmount_ <= DetailsOfFoundation.DocumentAmount Then
				NewRow.Sum = LineAmount_;
			Else
				NewRow.Sum = DetailsOfFoundation.DocumentAmount;
				NewRow.AmountARAP = 0;
			EndIf;
		Else
			NewRow = ARAPDetails.Add();
			NewRow.Sum = DetailsOfFoundation.DocumentAmount;
		EndIf;
		Object.DocumentAmount = ARAPDetails.Total("Sum");
		Object.Currency = DetailsOfFoundation.Currency;
	EndIf;
EndProcedure

&AtServer
Procedure SetVisibilityByProxyType()
	
	If Not ValueIsFilled(Object.AuthorizationLetterType) Then
		Object.AuthorizationLetterType = AuthorizationLetterType(Object);
	EndIf;
	
	If Object.AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveGoods Then
		Items.CashGroup.Visible = False;
		Items.GoodsPage.Visible = True;
		Items.MoneyPage.Visible = True;
		Items.PageTangibleAssets.Visible = False;
		Items.Pages.CurrentPage = Items.GoodsPage;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		
		Items.StateGroup.Visible = True;
	ElsIf Object.AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveCash Then
		Items.CashGroup.Visible = True;
		Items.GoodsPage.Visible = False;
		Items.MoneyPage.Visible = True;
		Items.PageTangibleAssets.Visible = False;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
		
		Items.StateGroup.Visible = True;
	Else
		Items.CashGroup.Visible = False;
		Items.GoodsPage.Visible = False;
		Items.MoneyPage.Visible = True;
		Items.PageTangibleAssets.Visible = True;
		Items.Pages.CurrentPage = Items.PageTangibleAssets;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		
		Items.StateGroup.Visible = False;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function AuthorizationLetterType(Object)
	
	AuthorizationLetterType = ?(Object.Goods.Count() > 0,
						PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveGoods"),
						?(Object.TangibleAssets.Count() > 0,
							PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveOtherMaterials"),
							PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash")));
	
	Return AuthorizationLetterType;
	
EndFunction

&AtClient
Function TypesOfBases_(AuthorizationLetterType)
	
	TypesOfBases_ = New Array;
	
	If AuthorizationLetterType = PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveGoods")
		Or AuthorizationLetterType = PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveOtherMaterials") Then
		
		TypesOfBases_.Add(Type("DocumentRef.PurchaseOrder"));
		TypesOfBases_.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
		TypesOfBases_.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
		TypesOfBases_.Add(Type("DocumentRef.SubcontractOrder2_5"));
	ElsIf Object.AuthorizationLetterType = PredefinedValue("Enum.TypesOfIssuedLettersOfAuthority.ToReceiveCash") Then
		
		TypesOfBases_.Add(Type("DocumentRef.CustomerInvoiceServices"));
		TypesOfBases_.Add(Type("DocumentRef.ReturnOfGoodsToVendor"));
		TypesOfBases_.Add(Type("DocumentRef.ReturnablePackagingRedemptionByCustomer"));
		TypesOfBases_.Add(Type("DocumentRef.RedemptionOfGoodsByCustodian"));
		TypesOfBases_.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
		TypesOfBases_.Add(Type("DocumentRef.SalesOrder"));
		TypesOfBases_.Add(Type("DocumentRef.ConsignmentReportFromCustomer"));
		TypesOfBases_.Add(Type("DocumentRef.CustomerInvoice"));
		TypesOfBases_.Add(Type("DocumentRef.CustomerInvoiceServicesAndAssets"));
		TypesOfBases_.Add(Type("CatalogRef.CounterpartyContracts"));
		TypesOfBases_.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
		TypesOfBases_.Add(Type("DocumentRef.ReportToMaterialProvider2_5"));
	EndIf;
	
	Return TypesOfBases_;
	
EndFunction

&AtServer
Procedure FillInUsingBaseDocumentServer()
	
	FillingData = Object.DocumentBasis;
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("DocumentRef.PurchaseOrder") Then
		FillInByOrderToSupplier(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		FillInRequestForReturnOfGoods(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.MaterialProviderOrder2_5") Then
		FillInByOrderOfGiver2_5(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.SubcontractOrder2_5") Then
		FillInByOrderToProcessor2_5(FillingData);
	EndIf;
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	
EndProcedure

&AtServer
Procedure FillInByOrderToSupplier(Val DocumentBasis)
	
	QueryText =
		"SELECT DISTINCT
		|	OrderingProducts.Ref AS Ref,
		|	OrderingProducts.Products AS Products,
		|	OrderingProducts.PartnerProducts AS PartnerProducts,
		|	OrderingProducts.Products.UnitOfMeasure AS UnitOfMeasure,
		|	OrderingProducts.Characteristic AS Characteristic,
		|	OrderingProducts.Package AS Package,
		|	OrderingProducts.LineNumber AS LineNumber,
		|	OrderingProducts.RowCode AS RowCode
		|INTO OrderData
		|FROM
		|	Document.PurchaseOrder.Goods AS OrderingProducts
		|WHERE
		|	OrderingProducts.Ref = &DocumentBasis
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrderingProducts.Products AS Products,
		|	OrderingProducts.PartnerProducts AS PartnerProducts,
		|	OrderingProducts.UnitOfMeasure AS UnitOfMeasure,
		|	OrderingProducts.Characteristic AS Characteristic,
		|	OrderingProducts.Package AS Package,
		|	PurchaseOrders.ToRegisterBalance / CASE
		|		WHEN OrderingProducts.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN 1
		|		ELSE &QueryTextPackagingFactor
		|	END AS NumberOfPackages
		|FROM
		|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder = &DocumentBasis
		|	AND Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
		|		VALUE(Enum.ItemsTypes.ReusablePackage))) AS PurchaseOrders
		|		INNER JOIN OrderData AS OrderingProducts
		|		ON PurchaseOrders.RowCode = OrderingProducts.RowCode
		|WHERE
		|	PurchaseOrders.ToRegisterBalance > 0
		|
		|ORDER BY
		|	OrderingProducts.LineNumber";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"OrderingProducts.Package",
		"OrderingProducts.Products"));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentBasis", DocumentBasis);
	QueryResults = Query.Execute();
	Object.Goods.Load(QueryResults.Unload());
	
EndProcedure

&AtServer
Procedure FillInRequestForReturnOfGoods(Val DocumentBasis)
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder = &DocumentBasis
		|		AND NOT ReferenceOrder.ThisIsOrderAsInvoice
		|		AND Products.ItemsType IN
		|			(VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode";
	TableFormationParameters.Indicators = "ToRegisterForReturns, RegisteredOnReturns";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.Indexes = "RowCode";
	TableFormationParameters.TempTableName = "TT_RequestsForReturnsTurnoverExpanded";
	
	TT_RequestsForReturnsTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = TT_RequestsForReturnsTurnoverExpanded +
	Common.QueryBatchSeparator() +
	"SELECT DISTINCT
	|	OrderingProducts.Ref AS Ref,
	|	OrderingProducts.Products AS Products,
	|	OrderingProducts.Products.UnitOfMeasure AS UnitOfMeasure,
	|	OrderingProducts.Characteristic AS Characteristic,
	|	OrderingProducts.Package AS Package,
	|	OrderingProducts.RowCode AS RowCode
	|INTO ProductData_7
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS OrderingProducts
	|WHERE
	|	OrderingProducts.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderingProducts.Products AS Products,
	|	UNDEFINED AS PartnerProducts,
	|	OrderingProducts.UnitOfMeasure AS UnitOfMeasure,
	|	OrderingProducts.Characteristic AS Characteristic,
	|	OrderingProducts.Package AS Package,
	|	(ReturnRequest.ForRegistrationOnReturnsQuantityTurnover -
	|		ReturnRequest.IssuedByReturnsQuantityTurnover) / CASE
	|		WHEN OrderingProducts.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor
	|	END AS NumberOfPackages
	|FROM
	|	TT_RequestsForReturnsTurnoverExpanded AS ReturnRequest
	|		INNER JOIN ProductData_7 AS OrderingProducts
	|		ON ReturnRequest.RowCode = OrderingProducts.RowCode
	|WHERE
	|	(ReturnRequest.ForRegistrationOnReturnsQuantityTurnover -
	|		ReturnRequest.IssuedByReturnsQuantityTurnover) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	OrderingProducts.Products,
	|	UNDEFINED,
	|	OrderingProducts.Products.UnitOfMeasure,
	|	OrderingProducts.Characteristic,
	|	OrderingProducts.Package,
	|	OrderingProducts.NumberOfPackages
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS OrderingProducts
	|WHERE
	|	OrderingProducts.Ref = &DocumentBasis
	|	AND OrderingProducts.Ref.ThisIsOrderAsInvoice
	|	AND OrderingProducts.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"OrderingProducts.Package",
		"OrderingProducts.Products"));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentBasis", DocumentBasis);
	QueryResults = Query.Execute();
	Object.Goods.Load(QueryResults.Unload());
EndProcedure


&AtServer
Procedure FillInByOrderToProcessor2_5(Val DocumentBasis)
	
	QueryText =
	"SELECT
	|	PurchaseOrders.Products AS Products,
	|	UNDEFINED                   AS PartnerProducts,
	|	PurchaseOrders.Products.UnitOfMeasure AS UnitOfMeasure,
	|	PurchaseOrders.Characteristic AS Characteristic,
	|
	|	ISNULL(OrderingProducts.Package, 
	|		ISNULL(StageGoods.Package,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			)
	|		) AS Package,
	|
	|	PurchaseOrders.ToRegisterBalance / CASE
	|		WHEN NOT OrderingProducts.Package IS NULL
	|				AND OrderingProducts.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN &QueryTextPackagingFactor1
	|		WHEN NOT StageGoods.Package IS NULL
	|				AND StageGoods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN &QueryTextPackagingFactor2
	|		ELSE 1 
	|	END AS NumberOfPackages
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder = &DocumentBasis) AS PurchaseOrders
	|		LEFT JOIN Document.SubcontractOrder2_5.ManufacturedProducts AS OrderingProducts
	|		ON PurchaseOrders.PurchaseOrder = OrderingProducts.Ref
	|			AND PurchaseOrders.RowCode = OrderingProducts.RowCode
	|		LEFT JOIN Document.ProductionStage2_2.ManufacturedProducts AS StageGoods
	|		ON PurchaseOrders.PurchaseOrder = StageGoods.Ref.SubcontractOrder
	|			AND PurchaseOrders.RowCode = StageGoods.RowCode
	|WHERE
	|	PurchaseOrders.ToRegisterBalance > 0
	|	AND (NOT OrderingProducts.Ref IS NULL
	|		OR NOT StageGoods.Ref IS NULL
	|		)
	|	AND PurchaseOrders.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"OrderingProducts.Package",
		"OrderingProducts.Products"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"StageGoods.Package",
		"StageGoods.Products"));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentBasis", DocumentBasis);
	QueryResults = Query.Execute();
	Object.Goods.Load(QueryResults.Unload());
	
EndProcedure

&AtServer
Procedure FillInByOrderOfGiver2_5(Val DocumentBasis)
	
	QueryText =
	"SELECT
	|	OrderingProducts.Ref                        AS Ref,
	|	OrderingProducts.Products                  AS Products,
	|	OrderingProducts.Products.UnitOfMeasure AS UnitOfMeasure,
	|	OrderingProducts.Characteristic                AS Characteristic,
	|	OrderingProducts.Package                      AS Package,
	|	OrderingProducts.RowCode                     AS RowCode
	|INTO ProductData_7
	|FROM
	|	Document.MaterialProviderOrder2_5.UsedMaterials AS OrderingProducts
	|WHERE
	|	OrderingProducts.Ref = &DocumentBasis
	|	AND NOT OrderingProducts.Canceled
	|
	|INDEX BY
	|	RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderingProducts.Products     AS Products,
	|	UNDEFINED                 AS PartnerProducts,
	|	OrderingProducts.UnitOfMeasure AS UnitOfMeasure,
	|	OrderingProducts.Characteristic   AS Characteristic,
	|	OrderingProducts.Package         AS Package,
	|	PurchaseOrders.ToRegisterBalance /
	|		CASE
	|			WHEN OrderingProducts.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN 1
	|			ELSE &QueryTextPackagingFactor
	|		END                    AS NumberOfPackages
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(
	|			,
	|			PurchaseOrder = &DocumentBasis
	|			AND Products.ItemsType IN (
	|								VALUE(Enum.ItemsTypes.OwnGoods), 
	|								VALUE(Enum.ItemsTypes.ReusablePackage))
	|			AND RowCode IN
	|					(SELECT
	|						ProductData_7.RowCode AS RowCode
	|					FROM
	|						ProductData_7 AS ProductData_7)) AS PurchaseOrders
	|
	|		LEFT JOIN ProductData_7 AS OrderingProducts
	|		ON PurchaseOrders.RowCode = OrderingProducts.RowCode
	|WHERE
	|	PurchaseOrders.ToRegisterBalance > 0";
		
	QueryText = StrReplace(
						QueryText,
						"&QueryTextPackagingFactor",
						Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
																				"OrderingProducts.Package",
																				"OrderingProducts.Products"));
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	Object.Goods.Load(Query.Execute().Unload());
	
EndProcedure


// Parameters:
// ValueSelected - CatalogRef.ProductCrossReferences
// AdditionalParameters - Structure
// 
&AtClient
Procedure ProcessResultOfSelectingPartnerProductName(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.CurrentRow.PartnerProducts = ValueSelected;
	
	GoodsPartnerProductsOnChange(AdditionalParameters.FormItem);
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	ElsIf Item.Name = "sh_ShamsiInput_ValidityEndDate" Then
		ValidityEndDateOnChange(Items.ValidityEndDate);
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
