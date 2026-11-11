///////////////////////////////////////////////////////////////////////////////////////////////////////
// The form is designed to search for nomenclature in the information database and 1C service:Nomenclature by barcode.
// Allows you to upload the nomenclature found in the service to the information database.
//
// The form is part of the programming interface of the subsystem of work with the Nomenclature. 
// It is allowed to embed the form as an independent object, 
// without using the functionality of the 1C service:Nomenclature.
//
// If you plan to use the form as an independent object,
// the following library objects are needed in addition to the form itself:
//   * General module.The work of the nomenclature of the client is undefined;
//   * General module.The work of the Nomenclature is undefined;
//   * Definable type.Nomenclature of work by Nomenclature; 
//   * Definable type.Characterization of the work by the nomenclature.
//
// When using the form as an independent object, 
// in the method of work, the nomenclature is undefined.The 
// search nomenclature of the hashcode of the creation of the server must set the values of the following form details:
//   * Use the characteristics of the nomenclature - Boolean - a sign of the use of characteristics.
//
// It is allowed to refer to the following details of the form:
//   * Barcodes of nomenclature - a table of barcodes of nomenclature.
//   * Use the characteristics of the nomenclature - a sign of the use of characteristics.
//
// When opening the form, you must specify notifications about closing the form, to which the structure with the result of the form will be transmitted.
//
// Form Parameters:
//   * Unknown Barcodes - Array - Array from the Structure - collection of barcodes of the nomenclature, where:
//     ** Barcode - String - barcode of the nomenclature.
//     ** Quantity - Line - quantity of the item.
//   * Actions with Unknown Barcodes - String - description of the action to be performed with unknown barcodes.
//                                                 Possible values: "Register a transfer document", "Only register".
//

#Region Variables

&AtClient
Var ClosingInProgress;

&AtClient
Var CheckingTSBeforeClose; //indication of the need to check the fullness of PM before closing

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	ThereIsASubsystemWorkWithProducts = ThereIsASubsystemWorkWithProducts();
	
	If ThereIsASubsystemWorkWithProducts Then
		UseItemVariants = ProductManagementModule().RecordsAreKeptAccordingToCharacteristics();
	EndIf;
	
	TheService1WithNomenclatureIsUsed = ServiceIsAvailable();
	
	CustomizeFormWhenCreatingIt();
	
	For Each BarcodeString_ In Parameters.UnknownBarcodes Do
		
		NewRow = ItemsBarcodes.Add();
		
		NewRow.SearchInTheServiceWasNotUsed = True;
		
		FillPropertyValues(NewRow, BarcodeString_);
		
	EndDo;
				
	ActionsWithUnknownBarcodes = Parameters.ActionsWithUnknownBarcodes;
	
	If ActionsWithUnknownBarcodes = "OnlyRegister" Then
		Items.WriteAndClose.Title = NStr("vi = 'Đăng ký mã vạch';
										|ru = 'Зарегистрировать штрихкоды';
										|en = 'Register barcodes'; fa = 'Register barcodes';
										|it = 'Registrare i codici a barre';
										|pl = 'Zarejestruj kody kreskowe';
										|tr = 'Barkodları kaydet'");
	Else
		Items.WriteAndClose.Title = NStr("vi = 'Chuyển vào chứng từ';
										|ru = 'Перенести в документ';
										|en = 'Add to document'; fa = 'افزودن به سند';
										|it = 'Trasferire nel documento';
										|pl = 'Przenieś do dokumentu';
										|tr = 'Belgeye taşı'");
	EndIf;
	
	WorkingWithProductItemsOverridable.SearchForProductsByBarcodeWhenCreatingThemOnServer(ThisForm);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CurrentItem = Items.ItemsBarcodesProducts;
	
	CheckingTSBeforeClose = False;
	
	GetProductsByBarcodes();
	
	WorkingWithProductItemsClientOverridable.SearchForProductsByBarcodeWhenOpening(ThisForm);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	WorkingWithProductItemsClientOverridable.SearchForProductsByBarcodeWhenClosing(ThisForm, Exit);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	WorkingWithProductItemsOverridable.
		SearchForProductsByBarcodeProcessingFillInChecks(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	Barcodes = New Array;
	
	WorkingWithProductItemsClientOverridable.
		ProductSearchByBarcodeNotificationProcessing(ThisObject, EventName, Parameter, Source, Barcodes);
		
	If ValueIsFilled(Barcodes) Then
		GetProductsByBarcodes(Barcodes);
	EndIf;	
		
	If EventName = "WorkingWithProducts_LoadingProducts" Then
		
		If Parameter.CreatedObjects.Count() = 0 Then
			Return;
		EndIf;
		
		ProductLines_1 = ItemsBarcodes.FindRows(
			New Structure("ProductsIdentifier", Parameter.CreatedObjects[0].ProductsIdentifier));
		
		For Each CollectionItem In ProductLines_1 Do
			CollectionItem.Products = Parameter.CreatedObjects[0].Products;
			CollectionItem.Registered = True;
		EndDo;
		
	EndIf;
		
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	WorkingWithProductItemsClientOverridable.ProductSearchByBarcodeSelectionProcessing(ThisObject, ValueSelected, ChoiceSource);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not ClosingInProgress And Not CheckingTSBeforeClose And Not Exit Then
		Cancel = True;
			
		If ActionsWithUnknownBarcodes = "OnlyRegister" Then
			QueryText = NStr("vi = 'Mã vạch sẽ không được đăng ký.';
							|ru = 'Штрихкоды не будут зарегистрированы.';
							|en = 'Barcodes will not be registered.'; fa = 'Barcodes will not be registered.';
							|it = 'I codici a barre non saranno registrati.';
							|pl = 'Kody kreskowe nie będą rejestrowane.';
							|tr = 'Barkodlar kaydedilmeyecektir.'");
		Else
			QueryText = NStr("vi = 'Hàng hóa sẽ không được chuyển vào chứng từ.
								|Hãy hoãn lại hàng hóa sang một bên như là hàng hóa chưa được quét.';
								|ru = 'Товары не будут перенесены в документ.
								|Отложите их в сторону как неотсканированные.';
								|en = 'These barcodes are not registered in the application.
								|We cannot add these items to the document. Please place them aside.'; fa = 'These barcodes are not registered in the application.
								|We cannot add these items to the document. Please place them aside.';
								|it = 'I prodotti non saranno riportati nel documento.
								|Metteteli da parte come non scannerizzati.';
								|pl = 'Wiersze pozycji nie zostaną przeniesione do dokumentu.
								|Odłóż je na bok, jako nieskanowane.';
								|tr = 'Ürünler belgeye transfer edilmeyecektir.
								|Bunları taranmamış olarak kenara koy.'");
		EndIf;					
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), QueryText, QuestionDialogMode.OKCancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersItemsBarcodes

&AtClient
Procedure ItemsBarcodesOnActivateRow(Item)
	
	ChangeDownloadButtonAvailability();
	
EndProcedure

&AtClient
Procedure ItemsBarcodesProductsOnChange(Item)
	
	WorkingWithProductItemsClientOverridable.
		SearchForProductsByBarcodeProductsWhenChanged(ThisForm, Item);
	
EndProcedure

&AtClient
Procedure ItemsBarcodesProductsCreating(Item, StandardProcessing)
	
	WorkingWithProductItemsClientOverridable.
		SearchForProductsByBarcodeProductsCreation(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ItemsBarcodesProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	WorkingWithProductItemsClientOverridable.
		SearchForProductsByBarcodeProductsStartSelection(ThisForm, Item, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ItemsBarcodesCharacteristicOnChange(Item)
	
	WorkingWithProductItemsClientOverridable.
		SearchForProductsByBarcodeCharacteristicWhenChanging(ThisForm, Item);
		
EndProcedure

&AtClient
Procedure ItemsBarcodesCharacteristicStartChoice(Item, ChoiceData, StandardProcessing)
	
	WorkingWithProductItemsClientOverridable.
		SearchForProductsByBarcodeCharacteristicsStartOfSelection(ThisForm, Item, ChoiceData, StandardProcessing);
		
EndProcedure

&AtClient
Procedure ItemsBarcodesCharacteristicCreating(Item, StandardProcessing)
	
	WorkingWithProductItemsClientOverridable.
		ProductSearchByBarcodeFeatureCreation(ThisForm, Item, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateProducts(Command)
	
	If Items.ItemsBarcodes.CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.ItemsBarcodes.CurrentData;
	
	If Not ValueIsFilled(CurrentData.ProductsIdentifier) Then
		Return;
	EndIf;
	
	ProductIDs = CommonClientServer.ValueInArray(
		New Structure("ProductsIdentifier, ItemVariantID", 
			CurrentData.ProductsIdentifier, CurrentData.ItemVariantID));
	
	CreateProductsById(ProductIDs);
	
EndProcedure

&AtClient
Procedure CreateAll(Command)
	
	If ItemsBarcodes.Count() = 0 Then
		Return;
	EndIf;
	
	IDs = New Array;
	
	For Each CollectionItem In ItemsBarcodes Do
		If ValueIsFilled(CollectionItem.ProductsIdentifier) 
			And Not ValueIsFilled(CollectionItem.Products) Then
			
			IDs.Add(New Structure("ProductsIdentifier, ItemVariantID", 
				CollectionItem.ProductsIdentifier, 
				CollectionItem.ItemVariantID));
		EndIf;
	EndDo;
	
	CreateProductsById(IDs);
	
EndProcedure

&AtClient
Procedure MoveToDocument(Command)
	
	ClearMessages();
	
	CloseParameter = RegisterBarcodesOnServer();
	If CloseParameter = Undefined Then
		Return;
	EndIf;	
		
	If CloseParameter.UnregisteredProductsFound Then
		
		If ActionsWithUnknownBarcodes = "OnlyRegister" Then
			If UseItemVariants Then
				QueryText = NStr("vi = 'Không phải đối với tất cả mã vạch mới đều có chỉ ra mặt hàng và đặc tính tương ứng.
				|Theo các mặt hàng này sẽ không ghi nhận mã vạch.';
				|ru = 'Не для всех новых штрихкодов указана соответствующая номенклатура и характеристика.
				|По этим позициям штрихкод не будет зарегистрирован.';
				|en = 'Items and variants are not specified for some of the new barcodes.
				|The barcode will not be registered for these items.'; fa = 'Items and variants are not specified for some of the new barcodes.
				|The barcode will not be registered for these items.';
				|it = 'Non per tutti i nuovi codici a barre sono indicati l''articolo e le caratteristiche corrispondenti.
				|Il codice a barre per queste voci non verrà registrato.';
				|pl = 'Nie wszystkie nowe kody kreskowe mają odpowiednią nomenklaturę i charakterystyki.
				|Kod kreskowy nie zostanie zarejestrowany dla tych pozycji.';
				|tr = 'Tüm yeni barkodlara karşılık gelen öğe ve özellik belirtilmedi.
				|Barkod bu konumlar için kaydedilmeyecektir.'");
			Else
				QueryText = NStr("vi = 'Không phải đối với tất cả mã vạch mới đều có chỉ ra mặt hàng và đặc tính tương ứng.
				|Theo các mặt hàng này sẽ không ghi nhận mã vạch.';
				|ru = 'Не для всех новых штрихкодов указана соответствующая номенклатура.
				|По этим позициям штрихкод не будет зарегистрирован.';
				|en = 'The corresponding products are specified not for all new barcodes.
				|Barcode will not be registered for these items.'; fa = 'The corresponding products are specified not for all new barcodes.
				|Barcode will not be registered for these items.';
				|it = 'Non per tutti i nuovi codici a barre è indicato l''articolo corrispondente.
				|Il codice a barre per queste voci non verrà registrato.';
				|pl = 'Nie wszystkie nowe kody kreskowe mają odpowiednią nomenklaturę.
				|Kod kreskowy nie zostanie zarejestrowany dla tych pozycji.';
				|tr = 'Tüm yeni barkodlara karşılık gelen öğe belirtilmedi.
				|Barkod bu konumlar için kaydedilmeyecektir.'");
			EndIf;
		Else	
			If UseItemVariants Then
				QueryText = NStr("vi = 'Không phải đối với tất cả mã vạch mới đều có chỉ ra mặt hàng và đặc tính tương ứng.
				|Các mặt hàng này sẽ không được chuyển vào chứng từ.
				|Hãy đặt chúng sang một bên như là các mặt hàng chưa được quét.';
				|ru = 'Не для всех новых штрихкодов указана соответствующая номенклатура и характеристика.
				|Эти товары не будут перенесены в документ.
				|Отложите их в сторону как неотсканированные.';
				|en = 'Items and variants are not specified for some of the new barcodes.
				|These goods will not be transferred to the document.
				|Put them aside as unscanned.'; fa = 'Items and variants are not specified for some of the new barcodes.
				|These goods will not be transferred to the document.
				|Put them aside as unscanned.';
				|it = 'Non per tutti i nuovi codici a barre sono indicati l''articolo e le caratteristiche corrispondenti.
				|Questi prodotti non saranno riportati sul documento.
				|Metteteli da parte come non scannerizzati.';
				|pl = 'Nie wszystkie nowe kody kreskowe mają odpowiednią nomenklaturę i charakterystyki.
				|Te elementy nie zostaną przeniesione do dokumentu.
				|Odłóż je na bok, jako nieskanowane.';
				|tr = 'Tüm yeni barkodlara karşılık gelen öğe ve özellik belirtilmedi.
				|Bu ürünler belgeye transfer edilmeyecektir.
				|Bunları taranmamış olarak kenara koy.'");
			Else
				QueryText = NStr("vi = 'Không phải đối với tất cả mã vạch mới đều có chỉ ra mặt hàng tương ứng.
				|Các mặt hàng này sẽ không được chuyển vào chứng từ.
				|Hãy đặt chúng sang một bên như là các mặt hàng chưa được quét.';
				|ru = 'Не для всех новых штрихкодов указана соответствующая номенклатура.
				|Эти товары не будут перенесены в документ.
				|Отложите их в сторону как неотсканированные.';
				|en = 'Items are not specified for some new barcodes.
				|These goods will not be transferred to the document.                       
				|Put them aside as not scanned.'; fa = 'Items are not specified for some new barcodes.
				|These goods will not be transferred to the document.                       
				|Put them aside as not scanned.';
				|it = 'Non per tutti i nuovi codici a barre è indicato l''articolo corrispondente.
				|Questi prodotti non saranno riportati nel documento.
				|Metteteli da parte come non scannerizzati.';
				|pl = 'Nie wszystkie nowe kody kreskowe mają odpowiednią nomenklaturę.
				|Te elementy nie zostaną przeniesione do dokumentu.
				|Odłóż je na bok, jako nieskanowane.';
				|tr = 'Tüm yeni barkodlara karşılık gelen öğe belirtilmedi.
				|Bu ürünler belgeye transfer edilmeyecektir. 
				| Bunları taranmamış olarak kenara koy..'");
			EndIf;
		EndIf;
		
		QuestionResult = Undefined;
		
		ShowQueryBox(New CallbackDescription("MoveToDocumentCompletion", ThisObject, New Structure("CloseParameter", CloseParameter)), QueryText, QuestionDialogMode.OKCancel);
		Return;
		
	EndIf;
	
	MoveFragmentToDocument(CloseParameter);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ThereIsASubsystemWorkWithProducts()
	
	SetPrivilegedMode(True);
	FunctionalOptionName = "UseTheWorkingWithAnItemService";
	ThereIsFunctionalOption = Metadata.FunctionalOptions.Find(FunctionalOptionName) <> Undefined;
	
	ServiceIsUsed = False;
	
	If ThereIsFunctionalOption Then
		ServiceIsUsed = GetFunctionalOption(FunctionalOptionName);
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return ServiceIsUsed;
	
EndFunction

&AtServer
Function ProductManagementModule()
	
	Return Common.CommonModule("WorkingWithProductItems");
	
EndFunction

&AtClient
Function ProductManagementModuleClient()
	
	Return CommonClient.CommonModule("WorkingWithProductItemsClient");
	
EndFunction

&AtServer
Procedure AdjustFormForLongOperation(ThisIsBeginningOfLongOperation, Mode)
	
	If Mode = "Search" Then
		Items.LongTermOperationLabel.Title = NStr("vi = 'Tìm kiếm mặt hàng';
													|ru = 'Поиск номенклатуры';
													|en = 'Items search'; fa = 'جستجوی اقلام';
													|it = 'Ricerca articolo';
													|pl = 'Wyszukiwanie towarów';
													|tr = 'Öğe arama'");
		Items.WriteAndClose.Enabled = True;
	ElsIf Mode = "Load" Then	
		Items.LongTermOperationLabel.Title = NStr("vi = 'Kết nhập mặt hàng';
													|ru = 'Загрузка номенклатуры';
													|en = 'Import products'; fa = 'Import products';
													|it = 'Download di articolo';
													|pl = 'Pobieranie towarów';
													|tr = 'Öğe dışa aktarma'");
		Items.WriteAndClose.Enabled = Not ThisIsBeginningOfLongOperation;
	EndIf;
		
	Items.GroupDecorationsOfLongActions.Visible = ThisIsBeginningOfLongOperation;
	Items.CreationButtonGroup.Enabled            = Not ThisIsBeginningOfLongOperation;
		
EndProcedure

&AtServer
Function ServiceIsAvailable()
	
	If ThereIsASubsystemWorkWithProducts Then
		
		GeneralModuleInternetUserSupport = Common.CommonModule("OnlineUserSupport");
		
		Result = ProductManagementModule().SubsystemFunctionalityIsAvailable()
			And GeneralModuleInternetUserSupport.AuthenticationDataOfOnlineSupportUserFilled();
	Else
		Result = False;
	EndIf;
		
	Return Result;
		
EndFunction

&AtClient
Procedure MoveFragmentToDocument(Val CloseParameter)
	
	CheckingTSBeforeClose = True;
	
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		CloseParameter.Insert("OwnerForm", FormOwner.UUID);
	EndIf;
	
	Close(CloseParameter);
	
	Notify("UnknownBarcodes", CloseParameter, "Peripherals");

EndProcedure

&AtServer
Function RegisterBarcodesOnServer()
	
	If Not CheckFilling() Then
		Return Undefined;
	EndIf;
	
	Cancel = False;
	
	RegisterBarcodesOnServerContinued(Cancel);
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	UnregisteredProductsFound = ItemsBarcodes.FindRows(New Structure("Registered, RegisteredByDataProcessor", False, False));
	
	RegisteredBarcodes = New Array;
	FoundRegisteredBarcodes = ItemsBarcodes.FindRows(New Structure("RegisteredByDataProcessor", True));
	For Each BarcodeString_ In FoundRegisteredBarcodes Do
		RegisteredBarcodes.Add(New Structure("Barcode, Count", BarcodeString_.Barcode, BarcodeString_.Count));
	EndDo;
	
	DeferredGoods = New Array;
	PendingItemsFound = ItemsBarcodes.FindRows(New Structure("Registered, RegisteredByDataProcessor", False, False));
	For Each BarcodeString_ In PendingItemsFound Do
		DeferredGoods.Add(New Structure("Barcode, Count", BarcodeString_.Barcode, BarcodeString_.Count));
	EndDo;
	
	NewBarcodesReceived = New Array;
	FoundReceivedBarcodes = ItemsBarcodes.FindRows(New Structure("Registered", True));
	For Each BarcodeString_ In FoundReceivedBarcodes Do
		NewBarcodesReceived.Add(New Structure("Barcode, Count", BarcodeString_.Barcode, BarcodeString_.Count));
	EndDo;
	
	CloseParameter = New Structure();
	
	CloseParameter.Insert("DeferredGoods",                  DeferredGoods);
	CloseParameter.Insert("RegisteredBarcodes",       RegisteredBarcodes);
	CloseParameter.Insert("NewBarcodesReceived",            NewBarcodesReceived);
	CloseParameter.Insert("UnregisteredProductsFound", UnregisteredProductsFound.Count() > 0);
	CloseParameter.Insert("ItemsBarcodes",             BarcodeData_());
	
	Return CloseParameter;
			
EndFunction

&AtServer
Function BarcodeData_()
	
	Barcodes = New Array;
	
	For Each CollectionItem In ItemsBarcodes Do
		If ValueIsFilled(CollectionItem.Products)
			And ValueIsFilled(CollectionItem.Barcode) Then
			
			DataOnBarcodes = New Structure;
			DataOnBarcodes.Insert("Products",   Undefined);
			DataOnBarcodes.Insert("Characteristic", Undefined);
			DataOnBarcodes.Insert("Barcode",       "");
			DataOnBarcodes.Insert("Count",     0);
			WorkingWithProductItemsOverridable.ItemSearchByBarcodeBarcodeData(DataOnBarcodes);
			
			FillPropertyValues(DataOnBarcodes, CollectionItem);
			
			Barcodes.Add(DataOnBarcodes);
		EndIf;
	EndDo;
	
	Return Barcodes;	
	
EndFunction

&AtServer
Procedure RegisterBarcodesOnServerContinued(Cancel)
	
	BarcodesForTesting = ItemsBarcodes.Unload().CopyColumns();
	LinesToWorkOut    = New Array;
	
	For Each BarcodeString_ In ItemsBarcodes Do
		
		If BarcodeString_.Registered Or Not ValueIsFilled(BarcodeString_.Products)
			Or (BarcodeString_.ItemVariantsAreUsed And Not ValueIsFilled(BarcodeString_.Characteristic))Then
			
			Continue;
		EndIf;
		
		FillPropertyValues(BarcodesForTesting.Add(), BarcodeString_);
		
		LinesToWorkOut.Add(BarcodeString_);
		
	EndDo;
	
	If BarcodesForTesting.Count() > 0 Then
		
		BeginTransaction();
		
		Try
			WorkingWithProductItemsOverridable.RegisterBarcodes(BarcodesForTesting);
			CommitTransaction();
		Except
			
			RollbackTransaction();
			
			ErrorDescription = NStr("vi = 'Khi ghi lại mã vạch đã xảy ra lỗi.
				|Mô tả bổ sung:
				|%AdditionalDetails%';
				|ru = 'При записи штрихкодов произошла ошибка.
				|Дополнительное описание:
				|%AdditionalDetails%';
				|en = 'An error occurred while writing barcodes.
				|Additional description:
				|%AdditionalDetails%'; fa = 'An error occurred while writing barcodes.
				|Additional description:
				|%AdditionalDetails%';
				|it = 'Si è verificato un errore durante la scrittura dei codici a barre.
				|Descrizione aggiuntiva:
				|%AdditionalDetails%';
				|pl = 'Wystąpił błąd podczas zapisywania kodów kreskowych.
				|Dodatkowy opis:
				|%AdditionalDetails%';
				|tr = 'Barkod kaydı sırasında hata oluştu.
				|Ek ayrıntılar:
				|%AdditionalDetails%'");
			Common.MessageToUser(
			StrReplace(ErrorDescription, "%AdditionalDetails%", ErrorInfo().Description));
			
			Cancel = True;
			
		EndTry;
		
		For Each CollectionItem In LinesToWorkOut Do
			CollectionItem.RegisteredByDataProcessor = True;	
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetProductsByBarcodes(Barcodes = Undefined)
	
	GetProductsByBarcodesInCurDatabase(Barcodes);
	
	If Barcodes.Count() = 0 Then
		Return;
	EndIf;
	
	If TheService1WithNomenclatureIsUsed Then
		GetProductsByBarcodeInService(Barcodes);
	EndIf;
		
EndProcedure

&AtClient
Procedure GetProductsByBarcodeInService(Barcodes)
	
	AdjustFormForLongOperation(True, "Search");
	
	CompletionParameters = New Structure;
	
	CreateProductsContinued = New CallbackDescription("GetProductsByBarcodesCompletion",
		ThisObject, CompletionParameters);
	
	ProductManagementModuleClient().GetProductsByBarcodes(
		CreateProductsContinued, 
		Barcodes, 
		ThisObject, 
		JobID, 
		Items.GroupDecorationsOfLongActions);	
	
EndProcedure
	
&AtClient
Procedure GetProductsByBarcodesCompletion(Result, AdditionalParameters) Export 
	
	ParseSearchResultByBarcode(Result);

EndProcedure

&AtServer
Procedure ParseSearchResultByBarcode(Result)
	
	AdjustFormForLongOperation(False, "Search");	
	
	If Not IsTempStorageURL(Result.ResultAddress) Then
		Return;
	EndIf;
	
	BarcodeData_ = GetFromTempStorage(Result.ResultAddress);
	DeleteFromTempStorage(Result.ResultAddress);
	
	If TypeOf(BarcodeData_) <> Type("ValueTable") Then
		Return;
	EndIf;
	
	ServiceBarcodes = ProductManagementModule().ExpandedBarcodeData(BarcodeData_);
	
	For Each CollectionItem In ItemsBarcodes Do
		
		If ValueIsFilled(CollectionItem.ProductsIdentifier) Then
			Continue;
		EndIf;
		
		CollectionItem.SearchInTheServiceWasNotUsed = False;
		
		LinesByBarcode = ServiceBarcodes.FindRows(New Structure("Barcode", CollectionItem.Barcode));
		
		If LinesByBarcode.Count() = 0 Then
			CollectionItem.CannotFindProductInTheService = True;
			Continue;
		EndIf;
		
		CollectionItem.CannotFindProductInTheService = False;	
		
		DataString1 = LinesByBarcode[0];
		
		CollectionItem.ServiceProducts         = DataString1.FullNameOfProduct;
		CollectionItem.ProductsIdentifier   = DataString1.ProductsIdentifier;
		CollectionItem.ItemVariantID = DataString1.ItemVariantID;
		CollectionItem.Count                  = 1;
		
	EndDo;
	
	ChangeAvailabilityOfDownloadAllButton();
	
EndProcedure
	
&AtServer
Procedure GetProductsByBarcodesInCurDatabase(Barcodes = Undefined)
	
	If Barcodes = Undefined Then
		Barcodes = ItemsBarcodes.Unload().UnloadColumn("Barcode");
	Else
		FindBarcodesAmongThoseAdded(Barcodes);
	EndIf;
	
	If Barcodes.Count() = 0 Then
		Return;
	EndIf;
	
	BarcodeData_ = New ValueTable;
	
	WorkingWithProductItemsOverridable.GetProductsByBarcodes(Barcodes, BarcodeData_);
	
	If BarcodeData_.Count() = 0 Then
		Return;
	EndIf;
	
	For Each CollectionItem In BarcodeData_ Do
		
		LinesByBarcode = ItemsBarcodes.FindRows(New Structure("Barcode", CollectionItem.Barcode));
		
		If LinesByBarcode.Count() <> 0 Then
			
			CurrentRow = LinesByBarcode[0];
			
			CurrentRow.Products                = CollectionItem.Products;
			CurrentRow.UnitOfMeasure            = CollectionItem.UnitOfMeasure;
			CurrentRow.Characteristic              = CollectionItem.Characteristic;
			CurrentRow.Registered             = True;
			CurrentRow.SearchInTheServiceWasNotUsed = True;
			CurrentRow.Count                  = 1;
			
			CommonClientServer.DeleteValueFromArray(Barcodes, CollectionItem.Barcode);
			
		EndIf;
	EndDo;
		
EndProcedure

&AtServer
Procedure FindBarcodesAmongThoseAdded(Barcodes)
	
	FoundBarcodes = New Array;
	
	For Each CollectionItem In Barcodes Do
		
		BarcodeStrings = ItemsBarcodes.FindRows(New Structure("Barcode", CollectionItem));
		
		If BarcodeStrings.Count() > 0 Then
			For Each CollectionItem In BarcodeStrings Do
				CollectionItem.Count = CollectionItem.Count + 1;
			EndDo;
			
			FoundBarcodes.Add(CollectionItem);
		EndIf;
	EndDo;	
	
	For Each CollectionItem In FoundBarcodes Do
		CommonClientServer.DeleteValueFromArray(Barcodes, CollectionItem);
	EndDo;
	
EndProcedure

&AtServer
Procedure CustomizeFormWhenCreatingIt()
	
	If Not TheService1WithNomenclatureIsUsed Then
		Items.ExplanationToForm.Title = 
			NStr("vi = 'Quét mã vạch sản phẩm để tìm mục và sau đó chuyển nó vào chứng từ.';
				|ru = 'Отсканируйте штрихкод товара для поиска номенклатуры и последующего переноса ее в документ.';
				|en = 'Scan a product barcode to find the products and transfer them to the document'; fa = 'Scan a product barcode to find the products and transfer them to the document';
				|it = 'Scannerizza il codice a barre della merce per la ricerca degli articoli e del suo successivo trasferimento nel documento.';
				|pl = 'Zeskanuj kod kreskowy towaru w celu poszukiwania nomenklatury i jej ostatniego przenoszenia do dokumentu.';
				|tr = 'Öğeyi aramak ve ardından bunu bir belgeye transfer etmek için ürün barkodunu tara.'")
	EndIf;
	
	Items.GroupDecorationsOfLongActions.Visible        = TheService1WithNomenclatureIsUsed;
	Items.ItemsBarcodesServiceProducts.Visible = TheService1WithNomenclatureIsUsed;
	
	If TheService1WithNomenclatureIsUsed Then
		
		RightToChangeData = ProductManagementModule().RightToChangeData();
		
		Items.CreationButtonGroup.Visible = RightToChangeData;
		Items.CreateAll.Visible           = RightToChangeData And ProductManagementModule().BatchCreationOfProductsIsAllowed();
		
	Else
 		Items.CreationButtonGroup.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	////////////////////////////////////////////////////////////////////////////////
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemsBarcodesCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemsBarcodes.ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	////////////////////////////////////////////////////////////////////////////////
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemsBarcodesServiceProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemsBarcodes.CannotFindProductInTheService");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không tìm thấy mặt hàng>';
													|ru = '<номенклатура не найдена>';
													|en = '<products are not found>'; fa = '<products are not found>';
													|it = '<articolo non trovato>';
													|pl = '<nomenklatura nie znaleziona>';
													|tr = '<öğe bulunamadı>'"));
		
	////////////////////////////////////////////////////////////////////////////////
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemsBarcodesServiceProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemsBarcodes.SearchInTheServiceWasNotUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có tìm kiếm đã được thực hiện>';
													|ru = '<поиск не производился>';
													|en = '<no search was performed>'; fa = '<no search was performed>';
													|it = '<nessuna ricerca è stata eseguita>';
													|pl = '<nie wykonano wyszukiwania>';
													|tr = '<arama yapılmadı>'"));
	
	////////////////////////////////////////////////////////////////////////////////
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemsBarcodesBarcode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemsBarcodes.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	////////////////////////////////////////////////////////////////////////////////
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemsBarcodesState.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemsBarcodes.Registered");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Font", Metadata.StyleItems.ImportantLabelFont.Value);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Mới';
													|ru = 'Новый';
													|en = 'New'; fa = 'جدید';
													|it = 'Nuovo';
													|pl = 'New';
													|tr = 'Yeni'"));

	////////////////////////////////////////////////////////////////////////////////
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemsBarcodesState.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemsBarcodes.Registered");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đã ghi nhận';
													|ru = 'Зарегистрирован';
													|en = 'Registered'; fa = 'ثبت‌شده';
													|it = 'Registrato';
													|pl = 'Registered';
													|tr = 'Kaydedildi'"));

EndProcedure

&AtClient
Procedure CreateProductsById(ProductIDs)
	
	AdjustFormForLongOperation(True, "Load");	
	
	CompletionParameters = New Structure;
	CompletionParameters.Insert("JobID", Undefined);
	
	CreateProductsContinued = New CallbackDescription("CreateProductsContinued",
		ThisObject, CompletionParameters);
	
	ProductManagementModuleClient().DownloadProductsAndSpecifications(
		CreateProductsContinued, 
		ProductIDs, 
		ThisObject, 
		Undefined,
		Undefined,
		Items.GroupDecorationsOfLongActions);
	
EndProcedure

&AtClient
Procedure CreateProductsContinued(Result, AdditionalParameters) Export 
	
	AdjustFormForLongOperation(False, "Load");
	
	If Result = Undefined Then
		Return;
	EndIf;
		
	FillInProducts(Result.NewItems);
	
	ChangeDownloadButtonAvailability();
	
EndProcedure

&AtServer
Procedure FillInProducts(CreatedProducts)
	
	For Each CollectionItem In CreatedProducts Do
		
		ById_Row = ItemsBarcodes.FindRows(
			New Structure("ProductsIdentifier, ItemVariantID", 
				CollectionItem.ProductsIdentifier, CollectionItem.ItemVariantID));
		
		For Each Barcode In ById_Row Do
			
			Barcode.Products = CollectionItem.Products;
			Barcode.Characteristic = CollectionItem.Characteristic;
			
			If ValueIsFilled(Barcode.Characteristic) Then
				Barcode.ItemVariantsAreUsed = True;
			EndIf;
			
			Barcode.Registered = True;
			
			WorkingWithProductItemsOverridable.
				SearchForProductsByBarcodeAfterLoadingProducts(Barcode, CollectionItem.Products);
			
		EndDo;
	
	EndDo;
	
	ChangeAvailabilityOfDownloadAllButton();
	
EndProcedure

&AtClient
Procedure ItemsBarcodesServiceProductsOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.ItemsBarcodes.CurrentData <> Undefined
		And ValueIsFilled(Items.ItemsBarcodes.CurrentData.ProductsIdentifier) Then
		
		ProductManagementModuleClient().OpenProductCardForm(
			CommonClientServer.ValueInArray(
				Items.ItemsBarcodes.CurrentData.ProductsIdentifier),
			ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.OK Then
		CheckingTSBeforeClose = True;
		ClosingInProgress = True;
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure MoveToDocumentCompletion(QuestionResult, AdditionalParameters) Export
	
	CloseParameter = AdditionalParameters.CloseParameter;
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	MoveFragmentToDocument(CloseParameter);

EndProcedure

&AtClient
Procedure ChangeDownloadButtonAvailability()
			
	CurrentData = Items.ItemsBarcodes.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf; 
	
	Items.CreateProducts.Enabled = 
		ValueIsFilled(CurrentData.ServiceProducts) 
			And Not ValueIsFilled(CurrentData.Products)
				And Not Items.GroupDecorationsOfLongActions.Visible;

EndProcedure

&AtServer
Procedure ChangeAvailabilityOfDownloadAllButton()
	
	ThereAreProductsToCreate = False;
	
	For Each CollectionItem In ItemsBarcodes Do
		If Not ValueIsFilled(CollectionItem.Products)
			And ValueIsFilled(CollectionItem.ServiceProducts) Then
			
			ThereAreProductsToCreate = True;
			Break;
		EndIf;
	EndDo;
	
	Items.CreateAll.Enabled = ThereAreProductsToCreate 
		And Not Items.GroupDecorationsOfLongActions.Visible;
		
EndProcedure

&AtClient
Procedure Attachable_SearchForItemsByBarcodeRunCommand(Command)
	
	WorkingWithProductItemsClientOverridable.SearchForItemsByBarcodeRunCommand(
		ThisObject,
		Command);
	
EndProcedure

&AtClient
Procedure Attachable_SearchForItemsByBarcodeONChange(Item)
	
	WorkingWithProductItemsClientOverridable.SearchForItemsByBarcodeONChange(
		ThisObject,
		Item);
	
EndProcedure

&AtClient
Procedure Attachable_ItemSearchByBarcodeCleaning(Item, StandardProcessing)
	
	WorkingWithProductItemsClientOverridable.ItemSearchByBarcodeCleaning(
		ThisObject,
		Item,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_SearchProductsByBarcodeCreating(Item, StandardProcessing) Export
	
	WorkingWithProductItemsClientOverridable.SearchProductsByBarcodeCreating(
		ThisObject,
		Item,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_ItemSearchByBarcodeStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	WorkingWithProductItemsClientOverridable.ItemSearchByBarcodeStartOfSelection(
		ThisObject,
		Item, 
		ChoiceData, 
		StandardProcessing);
	
EndProcedure

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
