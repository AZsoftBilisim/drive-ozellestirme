
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Basis") Then
		DetailsOfFoundation = Common.ObjectAttributesValues(Parameters.Basis, "Warehouse, Date");
		Object.Warehouse = DetailsOfFoundation.Warehouse;
		StocktakingPeriod.StartDate = BegOfDay(DetailsOfFoundation.Date);
		StocktakingPeriod.EndDate = EndOfMonth(CurrentSessionDate());
	Else
		Parameters.Property("Warehouse", Object.Warehouse);
		Parameters.Property("StocktakingPeriod", StocktakingPeriod);
	EndIf;
	
	If ValueIsFilled(StocktakingPeriod.StartDate) And ValueIsFilled(StocktakingPeriod.EndDate) Then 
		DetermineDateOfRegistrationOfWarehouseActs();
	EndIf;	
		
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		SoleCompany = SettingsValueCached.GetDefaultOrganization();
		If Not ValueIsFilled(SoleCompany) Then
			ErrorText = NStr("vi = 'Không thể lập biên bản kho vì trong tùy chỉnh chương trình chưa nhập thông tin về doanh nghiệp.';
							|ru = 'Невозможно оформить складские акты, т.к. в настройках программы не введены сведения об организации.';
							|en = 'Cannot register inventory adjustments as the company information is not entered in the application settings.'; fa = 'Cannot register inventory adjustments as the company information is not entered in the application settings.';
							|it = 'È impossibile regolarizzare gli atti di magazzino, perché nelle impostazioni del programma non sono inserite le informazioni sulla società.';
							|pl = 'Nie można utworzyć akta magazynowe, ponieważ w ustawieniach programu nie wprowadzono informacji o firmie.';
							|tr = 'Stok düzeltmeleri düzenlemek imkansızdır, çünkü uygulama ayarlarında iş yeri bilgisi girilmedi.'");
			Cancel = True;
			Raise ErrorText;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Object.Warehouse) 
		And Not GetFunctionalOption("UseSeveralWarehouses") Then
		Object.Warehouse = SettingsValueCached.GetDefaultWarehouse();
	EndIf;
	
	If GetFunctionalOption("UseGoodsQuality") Then
		Items.DecorationGroupManagementPageReSortingDamage.Title 
			= NStr("vi = 'Với mục đích tối ưu hóa số lượng ghi giảm và ghi tăng hàng hóa, nên tiến hành đối trừ theo kiểm kê và (hoặc) hàng hỏng.';
					|ru = 'С целью оптимизации количества списаний и оприходований товаров рекомендуется произвести зачеты по пересортице и (или) порче.';
					|en = 'To optimize the number of stock shortage and surplus, it is recommended that you reclass stock or change quality.'; fa = 'To optimize the number of stock shortage and surplus, it is recommended that you reclass stock or change quality.';
					|it = 'Al fine di ottimizzare il numero di storni e delle registrazioni di merci in contabilità, si raccomanda di effettuare la compensazione per riclassificazione e (o) deterioramento.';
					|pl = 'W celu optymalizacji ilości rozchodu i rejestracji towarów zaleca się przeprowadzić klasyfikację według zmiany gatunku i (lub) uszkodzeniu.';
					|tr = 'Ürünlerin zarara yazılması ve envanter girişi sayısını optimize etmek için, sıralama ve (veya) stok kalite değişikliği için denkleştirmeler yapılması önerilmektedir.'");
		Items.GroupProductsToBeReSortedToBeDamaged.Title 
			= NStr("vi = 'Hàng hóa được tính lại theo chuyển tồn hoặc hàng hỏng';
					|ru = 'Товары, зачитываемые по пересортице или порче';
					|en = 'Stock reclasses and quality changes'; fa = 'Stock reclasses and quality changes';
					|it = 'Le merci compensate per riclassificazione o deterioramento';
					|pl = 'Wiersze pozycji, kompensowane według zmiany gatunku lub uszkodzeniu';
					|tr = 'Sıralanmış veya stok kalite değişikliği olarak denkleştirilen ürünler'");
		Items.ProductsToBeReSortedToBeDamagedColumnGroupProductToBeDebited.Title
			= NStr("vi = 'Giảm giá hàng hóa / Hàng hóa chất lượng ban đầu';
					|ru = 'Списываемый товар / Товар исходного качества';
					|en = 'Stock shortage / Stock of original quality'; fa = 'کسری موجودی / موجودی با کیفیت اصلی';
					|it = 'Merce in fase di storno / Merce della qualità iniziale';
					|pl = 'Spisywany towar / Towar oryginalnej jakości';
					|tr = 'Zarar yazılan ürün / Orijinal kalitedeki ürün'");
		Items.GoodsToBeReSortedGroupOfColumnsGoodsToBeRegistered.Title
			= NStr("vi = 'Vận chuyển hàng hóa / Hàng hóa hư hỏng';
					|ru = 'Приходуемый товар / Испорченный товар';
					|en = 'Stock surplus / Stock of changed quality'; fa = 'مازاد موجودی / موجودی با کیفیت تغییریافته';
					|it = 'Merce da registrare / Merce deteriorata';
					|pl = 'Rejestrowany towar / Uszkodzony towar';
					|tr = 'Stok fazlası / Hasarlı ürün'")
	Else
		Items.DecorationGroupManagementPageReSortingDamage.Title 
			= NStr("vi = 'Với mục đích tối ưu hóa số lượng ghi giảm và ghi tăng hàng hóa, nên tiến hành tính lại theo chuyển tồn.';
					|ru = 'С целью оптимизации количества списаний и оприходований товаров рекомендуется произвести зачеты по пересортице.';
					|en = 'To optimize the number of stock shortage and surplus, it is recommended that you reclass stock.'; fa = 'To optimize the number of stock shortage and surplus, it is recommended that you reclass stock.';
					|it = 'Al fine di ottimizzare il numero di storni e delle registrazioni delle merci in contabilità, si raccomanda di effettuare la compensazione per riclassificazione.';
					|pl = 'W celu optymalizacji ilości rozchodu i rejestracji towarów zaleca się przeprowadzić klasyfikację według zmiany gatunku.';
					|tr = 'Ürünlerin zarara yazılması ve envanter girişi sayısını optimize etmek için, sıralama için denkleştirmeler yapılması önerilmektedir.'");
		Items.GroupProductsToBeReSortedToBeDamaged.Title
			= NStr("vi = 'Hàng hóa được tính lại theo chuyển tồn';
					|ru = 'Товары, зачитываемые по пересортице';
					|en = 'Goods offset by stock reclass'; fa = 'Goods offset by stock reclass';
					|it = 'Le merci da compensare per riclassificazione';
					|pl = 'Wiersze pozycji, kompensowane według zmiany gatunku';
					|tr = 'Yeniden sınıflandırmaya göre mahsup edilen ürünler'");
		Items.ProductsToBeReSortedToBeDamagedColumnGroupProductToBeDebited.Title
			= NStr("vi = 'Hàng hóa ghi giảm';
					|ru = 'Списываемый товар';
					|en = 'Goods to adjust'; fa = 'کالا برای تعدیل';
					|it = 'Merce da stornare';
					|pl = 'Spisany na straty towar';
					|tr = 'Zarar yazılan ürün'");
		Items.GoodsToBeReSortedGroupOfColumnsGoodsToBeRegistered.Title
			= NStr("vi = 'Hàng hóa đến';
					|ru = 'Приходуемый товар';
					|en = 'Stock surplus'; fa = 'اضافه موجودی';
					|it = 'Merce da registrare in contabilità';
					|pl = 'Przychodzący towar';
					|tr = 'Stok fazlası'");
	EndIf;
		
	If GetFunctionalOption("UseMultipleCompanies") Then
		Items.DecorationDocumentProcessingPage.Title = 
			NStr("vi = 'Biên bản kho đã lập có phân bổ theo doanh nghiệp. Nếu có các biên bản chưa kết chuyển thì hãy mở lại, điền các trường cần thiết và kết chuyển.';
				|ru = 'Сформированные согласно распределению по организациям складские акты. Если есть непроведенные акты - откройте их, заполните необходимые поля и проведите.';
				|en = 'Inventory adjustments generated according to assigned company stock. If there are unposted adjustments, open them, fill in the required fields and post.'; fa = 'Inventory adjustments generated according to assigned company stock. If there are unposted adjustments, open them, fill in the required fields and post.';
				|it = 'Gli atti del magazzino generati secondo la ripartizione per società. Qualora ci fossero gli atti non registrati bisogna aprili, compilare i campi richiesti e registrare.';
				|pl = 'Utworzone według podziału na firmy dokumenty magazynowe. Jeśli są niezatwierdzone akty - otwórz je, wypełnij niezbędne pola i zatwierdź.';
				|tr = 'İş yerlerine göre dağılıma göre oluşan stok düzeltmeleri. Kaydedilmemiş düzeltmeler varsa - bunları aç, gerekli alanları doldur ve kaydet.'");
	Else
		Items.DecorationDocumentProcessingPage.Title = 
			NStr("vi = 'Biên bản kho đã lập. Nếu có các biên bản chưa kết chuyển thì hãy mở ra, điền các trường cần thiết và kết chuyển.';
				|ru = 'Сформированные складские акты. Если есть непроведенные акты - откройте их, заполните необходимые поля и проведите.';
				|en = 'Generated inventory adjustments. If there are unposted adjustments, open them, fill in the required fields and post.'; fa = 'Generated inventory adjustments. If there are unposted adjustments, open them, fill in the required fields and post.';
				|it = 'Gli atti del magazzino generati. Qualora ci fossero gli atti non registrati bisogna aprili, compilare i campi richiesti e registrare.';
				|pl = 'Utworzone dokumenty magazynowe. Jeśli są niezatwierdzone akty - otwórz je, wypełnij niezbędne pola i zatwierdź.';
				|tr = 'Oluşturulan stok düzeltmeleri. Kaydedilmemiş düzeltmeler varsa - bunları aç, gerekli alanları doldur ve kaydet.'");
	EndIf;
	
	UsedByIntercompany = GetFunctionalOption("UseCustomerInvoiceIntercompany");	
	
	DataCompositionSchema = DataProcessors.WarehouseGoodsIssueReceiptWizard.GetTemplate("ItemFilterMain");
	DataProcessors.WarehouseGoodsIssueReceiptWizard.RedefineQueryTextOfTemplateSelectionOfMainItem(DataCompositionSchema);
	URLSchemes = PutToTempStorage(DataCompositionSchema, New UUID());
	SettingsSource = New DataCompositionAvailableSettingsSource(URLSchemes);
	FilterOfProductItem.Initialize(SettingsSource);
	FilterOfProductItem.LoadSettings(DataCompositionSchema.DefaultSettings);
	FilterOfProductItem.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	If Parameters.Property("FilterOfProductItem") Then
		If Parameters.FilterOfProductItem.Property("Products") Then
			DataCompositionClientServer.AddFilter(
				FilterOfProductItem, 
				"Products", 
				Parameters.FilterOfProductItem.Products, 
				DataCompositionComparisonType.InList);
		EndIf;
		If Parameters.FilterOfProductItem.Property("Characteristic") Then
			DataCompositionClientServer.AddFilter(
				FilterOfProductItem, 
				"Characteristic", 
				Parameters.FilterOfProductItem.Characteristic, 
				DataCompositionComparisonType.InList);
		EndIf;
		SetTitleOfProductSelectionScenery();
	EndIf;
	
	FillInDefaultValuesServer();
	WarehouseOnChangeServer();
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
	
	// Setting up Table Parts
	Items.GoodsToWriteOff.RowFilter = New FixedStructure("TransactionConsumption", True);
	Items.GoodsToRecordAsReceived.RowFilter = New FixedStructure("GoodsReceiptTransaction", True);
	Items.GoodsForMisgradingForDamage.RowFilter = New FixedStructure("DamageMisgradingOperation", True);
	Items.ProductsNotDistributed.RowFilter = New FixedStructure("NotAllocated", True);
	
	Object.SourseOfInformationAboutPricesForPrinting = Common.ObjectAttributeValue(Object.Warehouse, "SourseOfInformationAboutPricesForPrinting");
	If Not ValueIsFilled(Object.SourseOfInformationAboutPricesForPrinting) And Not GetFunctionalOption("UseSeveralPriceTypes") Then
		Object.SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost;
	EndIf;
	If Object.SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost Then
		Object.PriceKind = Undefined;
	Else
		Object.PriceKind = Catalogs.Warehouses.AccountingPriceType(Object.Warehouse);
	EndIf;
	SetNewKindOfPriceServer(Object.SourseOfInformationAboutPricesForPrinting);
	
	MetadataObjectsArray = New Array;
	MetadataObjectsArray.Add(Metadata.Documents.WriteOffOfGoodsShortages);
	MetadataObjectsArray.Add(Metadata.Documents.InventorySurplusRecognition);
	MetadataObjectsArray.Add(Metadata.Documents.GoodsDamage);
	MetadataObjectsArray.Add(Metadata.Documents.GoodsMisgrading);
	MetadataObjectsArray.Add(Metadata.Documents.PhysicalCountReport);
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = MetadataObjectsArray;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	If ValueIsFilled(Object.Warehouse) Then
		If Not WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Object.Warehouse) Then
		
			MessageText = NStr("vi = 'Trong kho %Warehouse%, không sử dụng sơ đồ hóa đơn kiêm phiếu xuất nhập khi lập hàng thừa, thiếu, hỏng, vì vậy không thể sử dụng trợ giúp lập biên bản.';
								|ru = 'На складе %Warehouse% не используется ордерная схема при оформлении излишков, недостач и порчи, поэтому невозможно использовать помощник оформления складских актов.';
								|en = 'Warehouse management is not used in warehouse ""%Warehouse%"" while recording surpluses, shortages and damage, so it is impossible to use the inventory adjustment wizard.'; fa = 'Warehouse management is not used in warehouse ""%Warehouse%"" while recording surpluses, shortages and damage, so it is impossible to use the inventory adjustment wizard.';
								|it = 'Al magazzino %Warehouse% non viene utilizzato lo schema dei mandati per la registrazione delle eccedenze, carenze e danni, pertanto non è possibile utilizzare l''assistente per la registrazione degli atti di magazzino.';
								|pl = 'Na magazynie %Warehouse% nie jest używany schemat zleceniowy przy tworzeniu nadwyżek, niedoborów oraz uszkodzeń, dlatego nie można użyć asystenta tworzenia aktów magazynowych.';
								|tr = 'Ambarda %Warehouse% fazlalıkları, eksiklikleri ve stok kalite değişikliği kaydederken ambar yönetimi kullanılmıyor, bu nedenle stok düzeltmelerini kaydetmek için sihirbazı kullanmak imkansızdır.'");
			MessageText = StrReplace(MessageText, "%Warehouse%", Object.Warehouse);
			Cancel = True;
			Raise MessageText;
		EndIf;
	EndIf;
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "DocumentsByBasis.Date",
		Items.DocumentsByBasisDate.Name);
	
	CustomizeFormLocalization();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	DecorationItemSelectionURLProcessingCompletion("", Undefined);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ConfirmationBeforeClosing Or Items.MainPanel.CurrentPage = Items.SettingsPage Then
		
		Return;
		
	ElsIf Not Items.MainPanel.CurrentPage = Items.DocumentProcessingPage Then
		
		StandardProcessing = False;
		Cancel = True;
		
		If Exit Then
			WarningText = NStr("vi = 'Chưa kết thúc quá trình lập phiếu kho.
				|Sẽ ngắt công việc của trợ giúp.';
				|ru = 'Процесс оформления складских актов не завершен.
				|Работа помощника будет прервана.';
				|en = 'Registration of inventory adjustments is not completed. 
				|The wizard will be closed.'; fa = 'Registration of inventory adjustments is not completed. 
				|The wizard will be closed.';
				|it = 'Il processo di registrazione degli atti di magazzino non è completato.
				|Il lavoro dell''assistente sarà interrotto.';
				|pl = 'Proces tworzenia aktów magazynowych nie został zakończony.
				|Praca asystenta będzie przerwana.';
				|tr = 'Stok düzeltmeleri düzenleme süreci tamamlanmadı.
				|Sihirbazın işi kesintiye uğrayacak.'");
			
			Return;
		EndIf;
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Đóng trợ giúp';
													|ru = 'Закрыть помощник';
													|en = 'Close the wizard'; fa = 'بستن دستیار';
													|it = 'Chiudere l''assistente';
													|pl = 'Zamknij asystenta';
													|tr = 'Sihirbazı kapat'"));
		ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Cancel';
													|tr = 'İptal'"));
		
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisForm);
		QueryText = NStr("vi = 'Chưa kết thúc lập biên bản.';
						|ru = 'Процесс оформления не завершен.';
						|en = 'Registration process is not completed.'; fa = 'Registration process is not completed.';
						|it = 'Il processo della registrazione non è completato.';
						|pl = 'Proces tworzenia nie został zakończony.';
						|tr = 'Düzenleme süreci tamamlanmadı.'");
		ShowQueryBox(Notification, QueryText, ButtonsList);
		
	Else
		
		StandardProcessing = False;
		Cancel = True;
		
		If Exit Then
			WarningText = NStr("vi = 'Công việc của Trợ giúp biên nhận kho sẽ bị gián đoạn.';
								|ru = 'Работа помощника оформления складских актов будет прервана.';
								|en = 'Wizard of inventory adjustment registration will be closed.'; fa = 'Wizard of inventory adjustment registration will be closed.';
								|it = 'Il lavoro dell''assistente per la registrazione degli atti del magazzino sarà interrotto.';
								|pl = 'Praca asystenta tworzenia aktów magazynowych będzie przerwana.';
								|tr = 'Stok düzeltmeleri düzenleme sihirbazının çalışmaları kesintiye uğrayacaktır.'");
			
			Return;
		EndIf;
		
		ConfirmButton(Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Val QuestionResult, Val AdditionalParameters) Export
	
	If QuestionResult = Undefined Or QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;

	ConfirmationBeforeClosing = True;
	Close();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Creation_WarehouseCertificates"
		Or EventName = "Write_WriteOffOfGoodsShortages"
		Or EventName = "Write_GoodsDamage"
		Or EventName = "Write_GoodsMisgrading"
		Or EventName = "Write_InventorySurplusRecognition"
		Or EventName = "Write_PhysicalCountReport" Then
		
		Items.DocumentsByBasis.Refresh();;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure StocktakingPeriodOnChange()
	
	InventoryPeriodForChangesOnServer();
	
EndProcedure

&AtClient
Procedure PickProductsLinesOnChange(Item)
	
	SetSelectionOfLinesByNomenclatureServer();
	
EndProcedure

&AtClient
Procedure PickProductsLinesClearing(Item, StandardProcessing)
	
	SetSelectionOfLinesByNomenclatureServer();
	
EndProcedure

&AtClient
Procedure SelectByOperationTypeStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;

	FormParameters = New Structure();
	FormParameters.Insert("SelectedOperations", SelectByOperationType.UnloadValues());
	
	Notification = New CallbackDescription("SelectByOperationTypeStartChoiceCompletion", ThisForm);
	OpenForm("DataProcessor.WarehouseGoodsIssueReceiptWizard.Form.SelectionFormOfTransactions",
				FormParameters, ThisForm, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectByOperationTypeStartChoiceCompletion(Val TransactionTypes, Val AdditionalParameters) Export
	
	If TransactionTypes = Undefined Then
		Return;
	ElsIf TransactionTypes.Count() = 0 Then
		SelectByOperationType.Clear();
	Else
		
		WriteOffText		= NStr("vi = 'Chi';
									|ru = 'Списание';
									|en = 'Stock shortage'; fa = 'کسری موجودی';
									|it = 'Storno';
									|pl = 'Spisanie';
									|tr = 'Gider yazmak'");
		TextEntry	= NStr("vi = 'Ghi tăng';
							|ru = 'Оприходование';
							|en = 'Stock surplus'; fa = 'اضافه موجودی';
							|it = 'Registrazione in contabilità';
							|pl = 'Rejestracja';
							|tr = 'Envanter girişi oluşturma'");
		TextSpoilage			= NStr("vi = 'Hàng hỏng';
										|ru = 'Порча';
										|en = 'Stock quality change'; fa = 'تغییر کیفیت موجودی';
										|it = 'Deterioramento';
										|pl = 'Uszkodzenie';
										|tr = 'Stok kalite değişikliği'");
		TextResortment	= NStr("vi = 'Chuyển tồn';
								|ru = 'Пересортица';
								|en = 'Stock reclass'; fa = 'تغییر طبقه موجودی';
								|it = 'Smistamento';
								|pl = 'Przesortowanie';
								|tr = 'Yeniden sınıflandırma'");
		
		For Each OperationType In TransactionTypes Do
			PresentationOperation = ?(OperationType = "WriteOff", WriteOffText,
										?(OperationType = "RecordingAsReceived", TextEntry,
										?(OperationType = "Damage", TextSpoilage,
										TextResortment)));
			
			SelectByOperationType.Add(OperationType, PresentationOperation);
		EndDo;
		
		For Each String In Object.Goods Do
			String.FilterFlag = Not SelectByOperationType.FindByValue(String.TransactionText) = Undefined;
		EndDo;
		
	EndIf;
	
	ProductsNotDistributedUpdateFilter();
	
EndProcedure

&AtClient
Procedure SelectByOperationTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectByOperationType.Clear();
	ProductsNotDistributedUpdateFilter();
	
EndProcedure

&AtClient
Procedure DecorationItemSelectionURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("DecorationItemSelectionURLProcessingCompletion", ThisForm);
	
	FormParameters = New Structure("Address", PlaceProductSelectionSettingsToTemporaryStorageServer(FilterOfProductItem));
	
	OpenForm(
		"DataProcessor.WarehouseGoodsIssueReceiptWizard.Form.CustomizeItemFilter",
		FormParameters,
		ThisForm,
		,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure DecorationItemSelectionURLProcessingCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined 
		Or Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	ProcessProductSelectionChanges(Result);
	
EndProcedure

&AtServer
Procedure ProcessProductSelectionChanges(FilterAddress)
	// loading the "Select nomenclature" setting
	SelectionOfProductsSetting = GetFromTempStorage(FilterAddress);
	DeleteFromTempStorage(FilterAddress);
	
	FilterOfProductItem.LoadSettings(SelectionOfProductsSetting);
	WarehouseOnChangeServer();
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(FilterOfProductItem);
	
	// formation of the representation of the "Selected nomenclature"
	SetTitleOfProductSelectionScenery();
	
EndProcedure

&AtClient
Procedure DecorationInformingAboutUnformedRecalculationsURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Warehouse", Object.Warehouse);
	
	FormParameters = New Structure("QuickFilterStructure, Status", QuickFilterStructure, "OnlyNotCompleted");
	
	OpenForm("Document.InventoryRecount.Form.ListForm", FormParameters, ThisForm);

EndProcedure

&AtClient
Procedure DecorationInformationAboutTheNumberOfProductsURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	Filter = New Structure("Warehouse", Object.Warehouse);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("VariantKey", "RegistrationOfSurplusShortagesContext");
	FormParameters.Insert("PurposeUseKey", "RegistrationOfSurplusShortagesContext");
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("ReportOptionsCommandsVisibility", False);
	FormParameters.Insert("Warehouse", Object.Warehouse);
	
	OpenForm("Report.UnregisteredSurplusesAndShortagesOfGoods.Form", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure SourseOfInformationAboutPricesForPrintingOnChange(Item)
	
	SourceOfPricingInformationToPrintWhenChangedOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsForMisgradingForDamage

&AtClient
Procedure GoodsForMisgradingForDamageBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	GoodsForMisgradingForDamageBeforeDeleteRowServer(Items.GoodsForMisgradingForDamage.SelectedRows);
	
EndProcedure

&AtClient
Procedure GoodsForMisgradingForDamageSelection(Item, RowSelected, Field, StandardProcessing)
	TSSelectionEventForItemsToBeDebited(Field, Item);		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsToWriteOff

&AtClient
Procedure GoodsToWriteOffSelection(Item, RowSelected, Field, StandardProcessing)
	ShowValue(,Item.CurrentData.ProductsWrittenOff);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsToRecordAsReceived

&AtClient
Procedure GoodsToRecordAsReceivedSelection(Item, RowSelected, Field, StandardProcessing)
	ShowValue(,Item.CurrentData.ProductsRecordedAsReceived);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAllocatedGoods

&AtClient
Procedure AllocatedGoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure AllocatedGoodsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	IdsOfSelectedRows = New Array;
	
	For Each SelectedRow In Items.AllocatedGoods.SelectedRows Do
		IdsOfSelectedRows.Add(SelectedRow);
	EndDo;
	
	For Each IDOfSelectedRow_ In IdsOfSelectedRows Do
		EditingGoodsDistributedLine(IDOfSelectedRow_, 0);
	EndDo;
	
	SortTableByOperationProductDescription(Object.AllocatedGoods);
	
EndProcedure

&AtClient
Procedure AllocatedGoodsQuantityIsAllocatedTextEditEnd(Item, Text, ChoiceData,
		Var_Parameters, StandardProcessing)
	
	EnteredValue = Number(Text);
	StandardProcessing = 
		Not (EnteredValue > Items.AllocatedGoods.CurrentData.QuantityIsAllocated Or EnteredValue < 0);
		
	If Not StandardProcessing Then
		QuantityFieldIsDistributed = CommonClientServer.PathToTabularSection("AllocatedGoods",
											Items.AllocatedGoods.CurrentData.LineNumber, "QuantityIsAllocated");
		CommonClientServer.MessageToUser(
			NStr("vi = 'Giá trị được nhập cần phải nhỏ hơn giá trị hiện tại và không nhỏ hơn 0.';
				|ru = 'Вводимое значение должно быть не более текущего и не менее нуля.';
				|en = 'Entered value must be less than the current one and not less than zero.'; fa = 'Entered value must be less than the current one and not less than zero.';
				|it = 'Il valore da inserire non deve essere superiore a quello attuale e non inferiore a zero.';
				|pl = 'Wprowadzona wartość nie może przekraczać bieżącej i nie być mniejszą niż zero.';
				|tr = 'Giriş değeri mevcut değerden büyük ve sıfırdan küçük olmamalıdır.'"), , 
			"Object." + QuantityFieldIsDistributed);
	Else
		EditingGoodsDistributedLine(Items.AllocatedGoods.CurrentRow, EnteredValue);
	EndIf;
	
EndProcedure

&AtClient
Procedure AllocatedGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	TSSelectionEventForItemsToBeDebited(Field, Item);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductsNotDistributed

&AtClient
Procedure ProductsNotDistributedSelection(Item, RowSelected, Field, StandardProcessing)
	TSSelectionEventForItemsToBeDebited(Field, Item);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocumentsByBasis

&AtClient
Procedure DocumentsByBasisSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	ShowValue(, DocumentReferenceByRecordKey(RowSelected));	
EndProcedure

&AtClient
Procedure DocumentsByBasisOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure DocumentsByBasisBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.DocumentsByBasis);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.DocumentsByBasis, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.DocumentsByBasis);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure SetOffByReSortingByDamage(Command)
	
	CurWriteOffData = Items.GoodsToWriteOff.CurrentData;
	If CurWriteOffData = Undefined Then
		MessageText = NStr("vi = 'Hãy chọn dòng ghi giảm cần tính lại.';
							|ru = 'Выделите строку списания, которую нужно зачесть.';
							|en = 'Select the line to process.'; fa = 'Select the line to process.';
							|it = 'Selezionare la riga di storno da compensare.';
							|pl = 'Zaznacz wiersz rozchodu, który trzeba kompensować.';
							|tr = 'Dengelemek istediğiniz gider yazma satırını seç.'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;
	
	CurRegistrationData = Items.GoodsToRecordAsReceived.CurrentData;
	If CurRegistrationData = Undefined Then
		MessageText = NStr("vi = 'Hãy chọn dòng ghi tăng cần tính lại.';
							|ru = 'Выделите строку оприходования, которую нужно зачесть.';
							|en = 'Select a recording as received line which should be set off.'; fa = 'Select a recording as received line which should be set off.';
							|it = 'Selezionare la riga di registrazione in contabilità da compensare.';
							|pl = 'Zaznacz wiersz rejestracji, który trzeba kompensować.';
							|tr = 'Denkleştirilecek envanter girişi satırını seç.'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;
		
	MaxValue = Min(CurWriteOffData.Count, CurRegistrationData.Count);
	MessageText = NStr("vi = 'Hãy chỉ ra số lượng để đối trừ (giá trị tối đa - %MaxValue%)';
						|ru = 'Укажите количество для зачета (максимальное значение - %MaxValue%)';
						|en = 'Specify a quantity to process (max value - %MaxValue%)'; fa = 'Specify a quantity to process (max value - %MaxValue%)';
						|it = 'Indicare l''importo per la compensazione (valore massimo - %MaxValue%)';
						|pl = 'Wprowadź ilość dla kompensaty (maksymalna wartość - %MaxValue%)';
						|tr = 'Mahsup edilecek tutarı belirt (maksimum değer - %MaxValue%)'");
	MessageText = StrReplace(MessageText, "%MaxValue%", MaxValue);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurWriteOffData", CurWriteOffData.GetID());
	AdditionalParameters.Insert("CurRegistrationData", CurRegistrationData.GetID());
	AdditionalParameters.Insert("MaxValue", MaxValue);
	AdditionalParameters.Insert("MessageText", MessageText);
	
	Notification = New CallbackDescription("SetOffByReSortingByDamageCompletion", ThisForm, AdditionalParameters);
	
	ShowInputNumber(Notification, MaxValue, MessageText, 15, 3);
	
EndProcedure

&AtClient
Procedure SetOffByReSortingByDamageCompletion(Val EnteredNumber, Val Var_Parameters) Export
	
	If EnteredNumber = Undefined Then
		Return;
	ElsIf EnteredNumber <= 0
		Or EnteredNumber > Var_Parameters.MaxValue Then
		
		If EnteredNumber > Var_Parameters.MaxValue Then
			MessageText = NStr("vi = 'Số lượng được chỉ định không được vượt quá số lượng tín dụng tối đa.';
								|ru = 'Указываемое количество не может превышать максимальное, зачитываемое количество.';
								|en = 'Specified quantity cannot exceed the maximum offset quantity.'; fa = 'Specified quantity cannot exceed the maximum offset quantity.';
								|it = 'La quantità indicata non può superare la quantità massima leggibile.';
								|pl = 'Podana ilość nie może przekraczać maksymalnej kompensowanej ilości.';
								|tr = 'Belirtilen tutar, mahsup edilen maksimum tutarı aşamaz.'");
		ElsIf EnteredNumber = 0 Then
			MessageText = NStr("vi = 'Số lượng chỉ định không thể bằng không.';
								|ru = 'Указываемое количество не может быть равно нулю.';
								|en = 'Specified quantity cannot equal zero.'; fa = 'Specified quantity cannot equal zero.';
								|it = 'La quantità indicata non può essere pari a zero.';
								|pl = 'Podana ilość nie może być równa zero.';
								|tr = 'Belirtilen miktar sıfıra eşit olamaz.'");
		Else
			MessageText = NStr("vi = 'Số lượng chỉ định không thể âm.';
								|ru = 'Указываемое количество не может быть отрицательным.';
								|en = 'Specified quantity cannot be negative.'; fa = 'Specified quantity cannot be negative.';
								|it = 'La quantità indicata non può essere negativa.';
								|pl = 'Podana ilość nie może być ujemną.';
								|tr = 'Belirtilen miktar olumsuz olamaz.'");
		EndIf;
		
		Notification = New CallbackDescription("SetOffByReSortingBySpoilageWarning", ThisForm, Var_Parameters);
		
		ShowMessageBox(Notification, MessageText);
		
	Else
		SetOffByReSortingByDamageCompletionServer(Var_Parameters, EnteredNumber);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetOffByReSortingBySpoilageWarning(Var_Parameters) Export
	
	Notification = New CallbackDescription("SetOffByReSortingByDamageCompletion", ThisForm, Var_Parameters);
	
	ShowInputNumber(Notification, Var_Parameters.MaxValue, Var_Parameters.MessageText, 15, 3);
	
EndProcedure

&AtClient
Procedure SetOffByReSortingTheCar(Command)
	
	Result = SetOffByReSortingTheCarServer();
	If Result = 0 Then
		ShowMessageBox(,NStr("vi = 'Trong số hàng hóa được ghi tăng và ghi giảm không có hàng hóa mà có thể đối trừ tự động.';
							|ru = 'Среди списываемых и приходуемых товаров нет товаров, по которым возможно провести автоматический зачет.';
							|en = 'In the list of stock shortage and surplus, there are no goods for which automatic processing is available.'; fa = 'In the list of stock shortage and surplus, there are no goods for which automatic processing is available.';
							|it = 'Tra le merci stornate e registrate in contabilità non ci sono merci per le quali è possibile effettuare la compensazione automatica.';
							|pl = 'Wśród rozchodowych i przyjętych na stan towarów nie ma towarów, dla których można przeprowadzić automatyczne zaliczenie.';
							|tr = 'İptal edilen ve stok fazlası olan ürünler arasında otomatik mahsup yapılması mümkün olan ürün bulunmamaktadır.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure CreditForDamageToTheCar(Command)
	
	Result = CreditForDamageToTheCarServer();
	If Result = 0 Then
		ShowMessageBox(,NStr("vi = 'Trong số hàng hóa được ghi tăng và ghi giảm không có hàng hóa mà có thể đối trừ tự động.';
							|ru = 'Среди списываемых и приходуемых товаров нет товаров, по которым возможно провести автоматический зачет.';
							|en = 'In the list of stock shortage and surplus, there are no goods for which automatic processing is available.'; fa = 'In the list of stock shortage and surplus, there are no goods for which automatic processing is available.';
							|it = 'Tra le merci stornate e registrate in contabilità non ci sono merci per le quali è possibile effettuare la compensazione automatica.';
							|pl = 'Wśród rozchodowych i przyjętych na stan towarów nie ma towarów, dla których można przeprowadzić automatyczne zaliczenie.';
							|tr = 'İptal edilen ve stok fazlası olan ürünler arasında otomatik mahsup yapılması mümkün olan ürün bulunmamaktadır.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure BackButton(Command)
	
	NoQuestionNeededForTransition = Not GoBack(True);
	
	If Not NoQuestionNeededForTransition Then
		ClearMessages();
		Return;
	EndIf;
		
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Trả lại';
												|ru = 'Вернуться';
												|en = 'Return'; fa = 'مرجوعی';
												|it = 'Ritornare';
												|pl = 'Return';
												|tr = 'Geri dön'"));
	ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Cancel';
												|tr = 'İptal'"));
	
	If  Items.MainPanel.CurrentPage = Items.DocumentProcessingPage Then
		
		Notification = New CallbackDescription("BackButtonCompletion", ThisForm, New Structure("DocumentsAreDeleted"));
		QueryText = NStr("vi = 'Tất cả biên bản đã tạo sẽ bị xóa. Quay lại ?';
						|ru = 'Все сформированные акты будут удалены. Вернуться назад?';
						|en = 'All the generated certificates will be removed. Return?'; fa = 'All the generated certificates will be removed. Return?';
						|it = 'Tutti gli atti generati saranno cancellati. Rientrare indietro?';
						|pl = 'Wszystkie utworzone akty zostaną usunięte. Cofnąć się?';
						|tr = 'Tüm oluşturulan düzeltmeler silinecektir. Geriye dön?'");
		ShowQueryBox(Notification, QueryText, ButtonsList);
		
	Else 		
		
		Notification = New CallbackDescription("BackButtonCompletion", ThisForm);
		QueryText = NStr("vi = 'Chưa kết thúc lập biên bản. Khi quay lại tùy chỉnh, các thông tin đã nhập sẽ bị xóa. Quay lại?';
						|ru = 'Процесс оформления не завершен. При возврате к настройкам введенная информация будет утеряна. Вернуться?';
						|en = 'Registration process is not completed. If you return to settings, entered data will be lost. Return?'; fa = 'Registration process is not completed. If you return to settings, entered data will be lost. Return?';
						|it = 'Il processo di registrazione non è completato. Al ritorno alle impostazioni le informazioni inserite andranno perse. Rientrare?';
						|pl = 'Proces tworzenia nie został zakończony. Po powrocie do ustawień wprowadzone dane zostaną utracone. Wrócić?';
						|tr = 'Düzenleme süreci tamamlanmadı. Ayarlara döndüğünüzde girilen bilgiler kaybolacaktır. Geriye dön?'");
		ShowQueryBox(Notification, QueryText, ButtonsList);
		
	EndIf;
		
	
EndProcedure

&AtClient
Procedure BackButtonCompletion(Val QuestionResult, Val AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		GoBack(False);
		If TypeOf(AdditionalParameters) = Type("Structure") And AdditionalParameters.Property("DocumentsAreDeleted") Then 
			Notify("Creation_WarehouseCertificates");
		EndIf;
		ClearMessages();
	EndIf;
	
EndProcedure

&AtClient
Procedure NextButton(Command)
	
	CurrentPage = Items.MainPanel.CurrentPage;
	If CurrentPage = Items.SettingsPage Then
		
		ClearMessages();
		HasErrors = False;
		If Not ValueIsFilled(Object.Warehouse) Then
			CommonClientServer.MessageToUser(NStr("vi = 'Hãy chọn kho.';
													|ru = 'Выберите склад.';
													|en = 'Select a warehouse.'; fa = 'یک انبار انتخاب کنید.';
													|it = 'Selezionare il magazzino.';
													|pl = 'Wybierz magazyn.';
													|tr = 'Ambar seç.'"), , "Object.Warehouse");
			HasErrors = True;
		EndIf;
		If Not ValueIsFilled(StocktakingPeriod.StartDate) Then
			CommonClientServer.MessageToUser(NStr("vi = 'Hãy chọn ngày bắt đầu kỳ kiểm kê.';
													|ru = 'Выберите дату начала инвентаризационного периода.';
													|en = 'Select start date of physical inventory count period.'; fa = 'Select start date of physical inventory count period.';
													|it = 'Selezionare la data di inizio del periodo di inventario.';
													|pl = 'Wybierz datę początku okresu inwentaryzacji.';
													|tr = 'Sayım dönemi için başlangıç ​​tarihini seç.'"), , "StocktakingPeriod");
			HasErrors = True;
		EndIf;
		If Not ValueIsFilled(StocktakingPeriod.EndDate) Then
			CommonClientServer.MessageToUser(NStr("vi = 'Hãy chọn ngày kết thúc kỳ kiểm kê.';
													|ru = 'Выберите дату окончания инвентаризационного периода.';
													|en = 'Select end date of physical inventory count period.'; fa = 'Select end date of physical inventory count period.';
													|it = 'Selezionare la data del termine del periodo di inventario.';
													|pl = 'Wybierz datę zakończenia okresu inwentaryzacji.';
													|tr = 'Sayım dönemi için bitiş ​​tarihini seç.'"), , "StocktakingPeriod");
			HasErrors = True;
		EndIf;
		If Not ValueIsFilled(WarehouseActDate) Then
			CommonClientServer.MessageToUser(NStr("vi = 'Hãy chọn ngày tạo biên bản kho.';
													|ru = 'Выберите дату оформления складских актов.';
													|en = 'Select inventory adjustment generation date.'; fa = 'Select inventory adjustment generation date.';
													|it = 'Selezionare la data di registrazione degli atti di magazzino.';
													|pl = 'Wybierz datę utworzenia aktów magazynowych.';
													|tr = 'Stok düzeltmeleri düzenleme tarihini seç.'"), , "WarehouseActDate");
			HasErrors = True;
		EndIf;
		If WarehouseActDate < StocktakingPeriod.StartDate 
			Or WarehouseActDate > StocktakingPeriod.EndDate Then
				
			CommonClientServer.MessageToUser(NStr("vi = 'Hãy chọn ngày tạo biên bản kho trong phạm vi kỳ kiểm kê.';
													|ru = 'Выберите дату оформления складских актов в рамках инвентаризационного периода.';
													|en = 'Select inventory adjustment generation date under the physical inventory count period.'; fa = 'Select inventory adjustment generation date under the physical inventory count period.';
													|it = 'Selezionare la data di registrazione degli atti di magazzino entro il periodo di inventario.';
													|pl = 'Wybierz datę utworzenia aktów magazynowych w ramach okresu inwentaryzacji.';
													|tr = 'Sayım dönemi kapsamında stok düzeltmeleri düzenleme tarihini seç.'"), , "WarehouseActDate");
			HasErrors = True;
		EndIf;
		If GoodsQuantityToRegisterWithFilterTakenIntoAccount = 0 Then
			ShowMessageBox(, NStr("vi = 'Không có hàng hóa cần lập biên bản kho.';
									|ru = 'Отсутствуют товары к оформлению складских актов.';
									|en = 'No goods to register inventory adjustments for.'; fa = 'No goods to register inventory adjustments for.';
									|it = 'Non ci sono merci per la registrazione degli atti di magazzino.';
									|pl = 'Brak towarów dla utworzenia aktów magazynowych.';
									|tr = 'Stok düzeltmeler düzenlemesi için ürün mevcut değil.'"));
			HasErrors = True;
		EndIf;
		
		If Not HasErrors Then
			
			SwitchingToOffsetStep();
			
		EndIf;
		
	ElsIf CurrentPage = Items.PageReSortingDamage Then
		
		SwitchingToDistributionByOrganizationsStep();
		
	ElsIf CurrentPage = Items.OrganizationDistributionPage Then
		
		If Object.AllocatedGoods.Count() = 0 Then
			ShowMessageBox(, NStr("vi = 'Hãy phân bổ hàng hóa theo doanh nghiệp.';
									|ru = 'Распределите товары по организациям.';
									|en = 'Assign company stock.'; fa = 'Assign company stock.';
									|it = 'Distribuire le merci per le società.';
									|pl = 'Rozprowadź wiersze pozycji według firmy.';
									|tr = 'İş yerlerine göre ürünleri dağıt.'"), , NStr("vi = 'Không có dữ liệu để lập';
																			|ru = 'Нет данных для оформления';
																			|en = 'No data for registration'; fa = 'No data for registration';
																			|it = 'Non ci sono dati per la registrazione';
																			|pl = 'Nie ma danych dla utworzenia';
																			|tr = 'Düzenleme için veri mevcut değil'"));
		Else
			GoToRegistrationOfActsStep();	
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfirmButton(Command)
	
	ArrayOfUnverifiedActs = Undefined;
	ArrayOfCompletedActs = Undefined;
	GetCompletedAndUnprovenWarehouseReports(WarehouseActs.UnloadValues(), ArrayOfUnverifiedActs, ArrayOfCompletedActs);
	If ArrayOfUnverifiedActs.Count() > 0 Then 
		ButtonsList = New ValueList;
		ButtonsList.Add("Cancel", NStr("vi = 'Tiếp tục lập biên bản';
										|ru = 'Продолжить проведение актов';
										|en = 'Continue posting inventory adjustments'; fa = 'Continue posting inventory adjustments';
										|it = 'Continuare la registrazione degli atti';
										|pl = 'Kontynuuj zatwierdzenie aktów';
										|tr = 'Düzeltme kaydını devam et'"));
		ButtonsList.Add("Close", NStr("vi = 'Đóng trợ giúp';
										|ru = 'Закрыть помощник';
										|en = 'Close the wizard'; fa = 'بستن دستیار';
										|it = 'Chiudere l''assistente';
										|pl = 'Zamknij asystenta';
										|tr = 'Sihirbazı kapat'"));
		QueryText = NStr("vi = 'Có các biên bản chưa kết chuyển.';
						|ru = 'Имеются непроведенные акты.';
						|en = 'There are unposted inventory adjustment documents.'; fa = 'There are unposted inventory adjustment documents.';
						|it = 'Ci sono atti non registrati.';
						|pl = 'Są niezatwierdzone akty.';
						|tr = 'Kaydedilmemiş düzeltmeler mevcut.'");
		
		Notification = New CallbackDescription("DoneActsNotCompletedButton", 
												ThisForm);
		ShowQueryBox(Notification, QueryText, ButtonsList);
	Else
		GoodsQuantity = GetNumberOfProductsToBeProcessed(False);
		If GoodsQuantity > 0 Then
			QueryText = NStr("vi = 'Chưa kết thúc lập biên bản kho theo %GoodsQuantity%.';
							|ru = 'Не закончено оформление складских актов по %GoodsQuantity%.';
							|en = 'Inventory adjustments are still being registered for %GoodsQuantity%.'; fa = 'Inventory adjustments are still being registered for %GoodsQuantity%.';
							|it = 'La registrazione degli atti del magazzino non è completata per %GoodsQuantity%.';
							|pl = 'Nie ukończono tworzenie aktów magazynowych dla%GoodsQuantity%.';
							|tr = '%GoodsQuantity% göre stok düzeltmeleri düzenlemesi bitmedi.'");
			QueryText = StrReplace(QueryText, "%GoodsQuantity%", "" + GoodsQuantity + " " +
				TMCommonUseClientServer.DeclensionOfWord(
					GoodsQuantity, 
					NStr("vi = 'cho hàng hóa, hàng hóa, hàng hóa, m';
						|ru = 'товару, товарам, товарам, м';
						|en = 'good, goods'; fa = 'good, goods';
						|it = 'товару, товарам, товарам, м';
						|pl = 'good, goods';
						|tr = 'ürün, ürün, ürünler, m'")));
			
			ButtonsList = New ValueList;
			ButtonsList.Add("GoToStep2", NStr("vi = 'Tiếp tục lập';
												|ru = 'Продолжить оформление';
												|en = 'Continue registration'; fa = 'Continue registration';
												|it = 'Continuare la registrazione';
												|pl = 'Kontynuować tworzenie';
												|tr = 'Düzenlemeye devam et'"));
			ButtonsList.Add("Close", NStr("vi = 'Đóng trợ giúp';
											|ru = 'Закрыть помощник';
											|en = 'Close the wizard'; fa = 'بستن دستیار';
											|it = 'Chiudere l''assistente';
											|pl = 'Zamknij asystenta';
											|tr = 'Sihirbazı kapat'"));
			Notification = New CallbackDescription("DoneButtonActsCompleted", ThisForm);
			ShowQueryBox(Notification,QueryText, ButtonsList);
		Else
			ConfirmationBeforeClosing = True;
			Notify("Creation_WarehouseCertificates");
			Close();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DoneButtonActsCompleted(Val QuestionResult, Val AdditionalParameters) Export
	
	If QuestionResult = Undefined Then
		Return;
	ElsIf QuestionResult = "GoToStep2" Then
		SwitchingToOffsetStep();
	ElsIf QuestionResult = "Close" Then
		ConfirmationBeforeClosing = True;
		Notify("Creation_WarehouseCertificates");
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure DoneActsNotCompletedButton(Val QuestionResult, Val AdditionalParameters) Export
	
	If QuestionResult = Undefined Or QuestionResult = "Cancel" Then
		Return;
	ElsIf QuestionResult = "Close" Then
		ConfirmationBeforeClosing = True;  
		Notify("Creation_WarehouseCertificates");
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseButton(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure ContinueWithNewFiltersButton(Command)
	
	ArrayOfUnverifiedActs = Undefined;
	ArrayOfCompletedActs = Undefined;
	GetCompletedAndUnprovenWarehouseReports(WarehouseActs.UnloadValues(), ArrayOfUnverifiedActs, ArrayOfCompletedActs);
	If ArrayOfUnverifiedActs.Count() > 0 Then 
		ButtonsList = New ValueList;
		ButtonsList.Add("Cancel", NStr("vi = 'Tiếp tục lập biên bản';
										|ru = 'Продолжить проведение актов';
										|en = 'Continue posting inventory adjustments'; fa = 'Continue posting inventory adjustments';
										|it = 'Continuare la registrazione degli atti';
										|pl = 'Kontynuuj zatwierdzenie aktów';
										|tr = 'Düzeltme kaydını devam et'"));
		ButtonsList.Add("ContinueWithNewSelections", NStr("vi = 'Tiếp tục với bộ lọc mới>';
															|ru = 'Продолжить с новыми отборами >';
															|en = 'Continue with new filters >'; fa = 'ادامه با فیلترهای جدید >';
															|it = 'Continuare con le nuove selezioni >';
															|pl = 'Kontynuuj z nowymi filtrami >';
															|tr = 'Yeni filtreler ile devam et >'"));
		QueryText = NStr("vi = 'Có các biên bản chưa kết chuyển.';
						|ru = 'Имеются непроведенные акты.';
						|en = 'There are unposted inventory adjustment documents.'; fa = 'There are unposted inventory adjustment documents.';
						|it = 'Ci sono atti non registrati.';
						|pl = 'Są niezatwierdzone akty.';
						|tr = 'Kaydedilmemiş düzeltmeler mevcut.'");
		
		Notification = New CallbackDescription("ContinueWithNewFiltersButtonCompletion", 
												ThisForm, New Structure("ArrayOfUnverifiedActs", ArrayOfUnverifiedActs));
		ShowQueryBox(Notification, QueryText, ButtonsList);
	Else
		GoodsQuantityToRegisterWithFilterTakenIntoAccount = GetNumberOfProductsToBeProcessed(False);
		If GoodsQuantityToRegisterWithFilterTakenIntoAccount > 0 Then
			QueryText = NStr("vi = 'Chưa kết thúc lập biên bản kho theo %GoodsQuantity%.';
							|ru = 'Не закончено оформление складских актов по %GoodsQuantity%.';
							|en = 'Inventory adjustments are still being registered for %GoodsQuantity%.'; fa = 'Inventory adjustments are still being registered for %GoodsQuantity%.';
							|it = 'La registrazione degli atti del magazzino non è completata per %GoodsQuantity%.';
							|pl = 'Nie ukończono tworzenie aktów magazynowych dla%GoodsQuantity%.';
							|tr = '%GoodsQuantity% göre stok düzeltmeleri düzenlemesi bitmedi.'");
			QueryText = StrReplace(QueryText, "%GoodsQuantity%", "" + GoodsQuantityToRegisterWithFilterTakenIntoAccount + " " +
				TMCommonUseClientServer.DeclensionOfWord(
					GoodsQuantityToRegisterWithFilterTakenIntoAccount, 
					NStr("vi = 'cho hàng hóa, hàng hóa, hàng hóa, m';
						|ru = 'товару, товарам, товарам, м';
						|en = 'good, goods'; fa = 'good, goods';
						|it = 'товару, товарам, товарам, м';
						|pl = 'good, goods';
						|tr = 'ürün, ürün, ürünler, m'")));
			
			ButtonsList = New ValueList;
			ButtonsList.Add("GoToStep2", NStr("vi = 'Tiếp tục lập';
												|ru = 'Продолжить оформление';
												|en = 'Continue registration'; fa = 'Continue registration';
												|it = 'Continuare la registrazione';
												|pl = 'Kontynuować tworzenie';
												|tr = 'Düzenlemeye devam et'"));
			ButtonsList.Add("ContinueWithNewSelections", NStr("vi = 'Tiếp tục với bộ lọc mới>';
																|ru = 'Продолжить с новыми отборами >';
																|en = 'Continue with new filters >'; fa = 'ادامه با فیلترهای جدید >';
																|it = 'Continuare con le nuove selezioni >';
																|pl = 'Kontynuuj z nowymi filtrami >';
																|tr = 'Yeni filtreler ile devam et >'"));
			
			Notification = New CallbackDescription("ContinueButtonWithNewSelectionsForSecondStepCompletion",
													ThisForm, New Structure("ArrayOfUnverifiedActs", ArrayOfUnverifiedActs));
			ShowQueryBox(Notification, QueryText, ButtonsList);
			
		Else
			GoToNewServerSelections();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinueWithNewFiltersButtonCompletion(Val Result, Val AdditionalParameters) Export
	
	If Result = Undefined Or Result = "Cancel" Then
		Return;
	EndIf;
	
	GoToNewServerSelections();
	
EndProcedure

&AtClient
Procedure ContinueButtonWithNewSelectionsForSecondStepCompletion(Val Result, Val AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf Result = "ContinueWithNewSelections" Then
		GoToNewServerSelections();
	ElsIf Result = "GoToStep2" Then
		SwitchingToOffsetStep();
	EndIf;
	
EndProcedure

&AtClient
Procedure DistributeForCompany(Command)
	
	If Not ValueIsFilled(Items.ProductsNotDistributed.SelectedRows) 
		Or Items.ProductsNotDistributed.SelectedRows.Count() = 0 Then
		
		MessageText = NStr("vi = 'Hãy chọn một hoặc nhiều dòng để phân bổ.';
							|ru = 'Выделите одну или несколько строк для распределения.';
							|en = 'Select one or several lines for allocation.'; fa = 'Select one or several lines for allocation.';
							|it = 'Selezionare una o più righe per la ripartizione.';
							|pl = 'Zaznacz jeden lub kilka wierszy dla podziału.';
							|tr = 'Dağıtım için bir veya daha fazla satırı seç.'");
		ShowMessageBox(Undefined, MessageText);
		
		Return;
		
	EndIf;
	
	Notification = New CallbackDescription("DistributeForCompanyCompletion", ThisForm);
	
	OpenForm("Catalog.Companies.ChoiceForm", , ThisForm, New UUID, , , Notification,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure DistributeForCompanyCompletion(Val Result, Val Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	DistributeForCompanyCompletionServer(Result, Items.ProductsNotDistributed.SelectedRows);
	
EndProcedure

&AtClient
Procedure AllocateAmongOwners(Command)
	
	If Not ValueIsFilled(Items.ProductsNotDistributed.SelectedRows)
		Or Items.ProductsNotDistributed.SelectedRows.Count() = 0 Then
		
		MessageText = NStr("vi = 'Hãy chọn một hoặc nhiều dòng để phân bổ.';
							|ru = 'Выделите одну или несколько строк для распределения.';
							|en = 'Select one or several lines for allocation.'; fa = 'Select one or several lines for allocation.';
							|it = 'Selezionare una o più righe per la ripartizione.';
							|pl = 'Zaznacz jeden lub kilka wierszy dla podziału.';
							|tr = 'Dağıtım için bir veya daha fazla satırı seç.'");
		ShowMessageBox(Undefined, MessageText);
		
		Return;
		
	EndIf;
	
	CompanyArray = New Array;
	
	For Each String In Object.SelectedCompanies Do
		CompanyArray.Add(String.Organization);
	EndDo;
	
	FormParameters = New Structure("CompanyArray", CompanyArray);
	Notification     = New CallbackDescription("AllocateAmongOwnersCompletion", ThisForm);
	
	OpenForm("DataProcessor.WarehouseGoodsIssueReceiptWizard.Form.SelectionFormOfCompanyMain",
		FormParameters, ThisForm, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AllocateAmongOwnersCompletion(Val Result, Val AdditionalParameters) Export
	
	If Result = Undefined Then 
		Return;
	ElsIf TypeOf(Result) = Type("Array")
		And Result.Count() = 0 Then
		
		MessageText = NStr("vi = 'Chưa chọn doanh nghiệp để phân bổ.';
							|ru = 'Не выбрано организаций для распределения.';
							|en = 'Companies for allocation are not selected.'; fa = 'Companies for allocation are not selected.';
							|it = 'Nessuna società selezionata per la ripartizione.';
							|pl = 'Nie wybrano firm dla podziału.';
							|tr = 'Dağıtım için iş yerleri seçilmedi.'");
		ShowMessageBox(Undefined, MessageText);
		
		Return;
		
	EndIf;
	
	CreatedRows = DistributeByOrganizationCompletionServer(Result, AdditionalParameters);
	
	If CreatedRows = 0 Then
		MessageText = NStr("vi = 'Không thể phân bổ tự động theo doanh nghiệp. Có thể là trong doanh nghiệp được chọn không có số dư theo hàng hóa đã chọn.';
							|ru = 'Не удалось провести автоматическое распределение по организациям. Возможно у выбранных организаций нет остатков по выбранным товарам.';
							|en = 'Cannot automatically assign company stock for adjustment. The selected companies may not have remaining selected goods.'; fa = 'Cannot automatically assign company stock for adjustment. The selected companies may not have remaining selected goods.';
							|it = 'Non è stato possibile eseguire ripartizione automatica per aziende. Le aziende selezionate potrebbero non avere giacenze di merci selezionate.';
							|pl = 'Nie było możliwe przeprowadzenie automatycznej dystrybucji do firm. Być może wybrane firmy nie mają równowagi na wybranych produktach.';
							|tr = 'İş yerlerine otomatik dağıtım yapılamadı. Seçilen iş yerlerinin seçilen ürünler için bakiyeleri olmayabilir.'");
		ShowMessageBox(Undefined, MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure CompanyStockBalanceReport(Command)
	
	TableInLine = PrepareTableOfProductsForServerReport();
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", New Structure("Warehouse, TableInLine", Object.Warehouse, TableInLine));
	FormParameters.Insert("FixedSettings");
	FormParameters.Insert("PurposeUseKey");
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("ReportOptionsCommandsVisibility", False);
		
	If UsedByIntercompany Then
		FormParameters.Insert("VariantKey", "ResiduesOfGoodsForDistributionOfShortagesAndSurplusesOfIntercampany");
	Else
		FormParameters.Insert("VariantKey", "ResiduesOfGoodsForDistributionOfShortagesAndSurpluses");
	EndIf;
	
	OpenForm("Report.CompanyStockBalance.Form", FormParameters, ThisForm);
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InventoryPeriodForChangesOnServer()
	
	If ValueIsFilled(Object.Warehouse) Then
		GoodsQuantityToRegister = GetNumberOfProductsToBeProcessed(True);
		GoodsQuantityToRegisterWithFilterTakenIntoAccount = GetNumberOfProductsToBeProcessed(False);	
		CheckBoxThereAreIncompleteRecountsInTheWarehouse = ThereAreUnformulatedWarehouseRecalculationsServer(Object.Warehouse);		
	Else
		CheckBoxThereAreIncompleteRecountsInTheWarehouse = False;
	EndIf;
	
	DetermineDateOfRegistrationOfWarehouseActs();
	
	ManageDecorationsByProduct();
	
EndProcedure

&AtServer
Procedure ManageDecorationsByProduct()
	
	TitleDecorations = Undefined; 
	
	If Not ValueIsFilled(Object.Warehouse) And Not ValueIsFilled(StocktakingPeriod) Then 
		TitleDecorations = NStr("vi = 'Điền vào các trường ""Kho"" và ""Kỳ của danh sách hàng tồn kho"" để xác định hàng hóa cần thiết để rút ra các Biên bản kho.';
								|ru = 'Заполните поля ""Склад"" и ""Период инвентаризационной описи"" для определения товаров, по которым необходимо оформить складские акты.';
								|en = 'Fill in fields ""Warehouse"" and ""Physical inventory register period"" to identify the goods for which it is required to register inventory adjustments.'; fa = 'Fill in fields ""Warehouse"" and ""Physical inventory register period"" to identify the goods for which it is required to register inventory adjustments.';
								|it = 'Compilare i campi ""Magazzino"" e ""Periodo dell''elenco di inventario"" per determinare le merci per le quali è necessario emettere atti di magazzino.';
								|pl = 'Wypełnij pola ""Magazyn"" i ""Okres inwentaryzacji"" w celu określenia towarów, dla których należy utworzyć dokumenty magazynowe.';
								|tr = 'Stok düzeltmeleri yapılması gereken ürünleri belirlemek için ""Ambar"" ve ""Envanter kaydı dönemi"" alanlarını doldur.'");
	ElsIf ValueIsFilled(Object.Warehouse) And Not ValueIsFilled(StocktakingPeriod) Then 
		TitleDecorations = NStr("vi = 'Điền vào trường ""Kỳ của danh sách hàng tồn kho"" để xác định hàng hóa cần thiết để rút ra các Biên bản kho.';
								|ru = 'Заполните поле ""Период инвентаризационной описи"" для определения товаров, по которым необходимо оформить складские акты.';
								|en = 'Fill in field Physical inventory register period"" to determine goods for which it is required to register inventory adjustments.'; fa = 'Fill in field Physical inventory register period"" to determine goods for which it is required to register inventory adjustments.';
								|it = 'Compilare il campo ""Periodo dell''elenco di inventario"" per determinare le merci per le quali è necessario emettere atti di magazzino.';
								|pl = 'Wypełnij pole ""Okres listy zasobów"", aby określić towary, dla których chcesz wystawić certyfikaty magazynowe.';
								|tr = 'Stok düzeltmeleri yapılması gereken ürünleri belirlemek için ""Envanter kaydı dönemi"" alanını doldur.'");
	ElsIf Not ValueIsFilled(Object.Warehouse) And ValueIsFilled(StocktakingPeriod) Then
		TitleDecorations = NStr("vi = 'Điền vào trường ""Kho"" để xác định hàng hóa mà Cần để vẽ Biên bản kho.';
								|ru = 'Заполните поле ""Склад"" для определения товаров, по которым необходимо оформить складские акты.';
								|en = 'Fill in field ""Warehouse"" to determine goods for which it is required to register inventory adjustments.'; fa = 'Fill in field ""Warehouse"" to determine goods for which it is required to register inventory adjustments.';
								|it = 'Compilare il campo ""Magazzino"" per determinare le merci per le quali è necessario emettere atti di magazzino.';
								|pl = 'Wypełnij pole ""Magazyn"", aby określić towary, dla których konieczne jest wystawienie certyfikatów magazynowych.';
								|tr = 'Stok düzeltmelerine göre düzenlenmesi gereken ürünleri belirlemek için ""Ambar"" alanını doldur.'");
	ElsIf GoodsQuantityToRegister = 0 Then 
		TitleDecorations = NStr("vi = 'Không cần lập biên bản kho.';
								|ru = 'Не требуется оформление складских актов.';
								|en = 'Inventory adjustment registration is not required.'; fa = 'Inventory adjustment registration is not required.';
								|it = 'La formalizzazione degli atti di magazzino non è richiesta.';
								|pl = 'Utworzenie aktów magazynowych nie jest wymagane.';
								|tr = 'Stok düzeltmelerinin düzenlenmesi gerekmiyor.'");
	ElsIf GoodsQuantityToRegisterWithFilterTakenIntoAccount = 0 Then
		RowsArray = New Array;
		RowsArray.Add(NStr("vi = 'Theo kho đã chọn có';
							|ru = 'По выбранному складу есть';
							|en = 'For the selected warehouse there is'; fa = 'For the selected warehouse there is';
							|it = 'Per il magazzino selezionato ci sono';
							|pl = 'Dla wybranego magazynu jest';
							|tr = 'Seçili ambara göre mevcut'") + " ");
		RowsArray.Add(New FormattedString(NStr("vi = 'hàng hóa';
												|ru = 'товары';
												|en = 'goods'; fa = 'goods';
												|it = 'merci';
												|pl = 'goods';
												|tr = 'ürünler'"),,,,"report"));
		RowsArray.Add(NStr("vi = ', mà theo đó cần lập biên bản kho, nhưng không có hàng hóa thỏa mãn bộ lọc đã thiết lập. Hãy thay đổi bộ lọc:';
							|ru = ', по которым необходимо оформить складские акты, но нет товаров удовлетворяющих установленному фильтру. Измените фильтр:';
							|en = ', which require inventory adjustments, but the set filter shows no goods. Change the filter:'; fa = ', which require inventory adjustments, but the set filter shows no goods. Change the filter:';
							|it = ', per cui è necessario emettere gli atti di magazzino, ma non ci sono prodotti corrispondenti al filtro stabilito. Modificate il filtro:';
							|pl = ', według których należy utworzyć dokumenty magazynowe, ale nie ma towarów spełniających kryteria ustawionego filtru. Zmień filtr:';
							|tr = ', bunun için stok düzeltmeleri düzenlemesinin gerekli olduğu, ancak belirtilen filtreyi karşılayan hiçbir ürünün bulunmadığı. Filtreyi değiştir:'"));
		TitleDecorations = New FormattedString(RowsArray);
	Else
		RowsArray = New Array;
		RowsArray.Add(NStr("vi = 'Có';
							|ru = 'Есть';
							|en = 'Yes'; fa = 'بله';
							|it = 'Ci sono';
							|pl = 'Yes';
							|tr = 'Var'") + " ");
		RowsArray.Add(New FormattedString(NStr("vi = 'hàng hóa';
												|ru = 'товары';
												|en = 'goods'; fa = 'goods';
												|it = 'merci';
												|pl = 'goods';
												|tr = 'ürünler'"),,,,"report"));
		RowsArray.Add(NStr("vi = ', mà theo đó cần tạo biên bản kho. Để hạn chế danh sách mặt hàng cần xử lý, hãy sử dụng bộ lọc:';
							|ru = ', по которым необходимо оформить складские акты. Для ограничения списка обрабатываемой номенклатуры воспользуйтесь фильтрами:';
							|en = ', which require inventory adjustments. To restrict the list of processed products, use the filters:'; fa = ', which require inventory adjustments. To restrict the list of processed products, use the filters:';
							|it = ', per cui è necessario emettere gli atti di magazzino. Per limitare l''elenco degli articoli da elaborare, utilizzate i filtri:';
							|pl = ', według których należy utworzyć dokumenty magazynowe. W celu ograniczenia listy przetwarzanej nomenklatury skorzystaj z filtrów:';
							|tr = ', bunun için stok düzeltmeleri düzenlemesi gerekir. İşlenmekte olan ürün gamı listesini sınırlamak için filtreleri kullan:'"));		
		TitleDecorations = New FormattedString(RowsArray);
	EndIf;
	
	Items.DecorationInformationAboutTheNumberOfProducts.Title = TitleDecorations;
	
EndProcedure

&AtServer
Procedure ProductsNotDistributedUpdateFilter()
	
	If SelectByOperationType.Count() = 0 Then
		Items.ProductsNotDistributed.RowFilter = New FixedStructure("NotAllocated", True);
	Else
		Items.ProductsNotDistributed.RowFilter = New FixedStructure("NotAllocated, FilterFlag",
											True, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure EditingGoodsDistributedLine(Val RowIdProductsDistributed, Val NewValueQuantity)
	
	LineGoodsDistributed = Object.AllocatedGoods.FindByID(RowIdProductsDistributed);
	LineProducts_ = Object.Goods.FindByID(LineGoodsDistributed.ConnectionKey);
	LineProducts_.QuantityIsAllocated = LineProducts_.QuantityIsAllocated -
		(LineGoodsDistributed.QuantityIsAllocated - NewValueQuantity);
	LineProducts_.QuantityNotAllocated = LineProducts_.QuantityNotAllocated + 
		(LineGoodsDistributed.QuantityIsAllocated - NewValueQuantity);
	LineProducts_.Allocated = Not LineProducts_.QuantityIsAllocated = 0;
	LineProducts_.NotAllocated = Not LineProducts_.QuantityNotAllocated = 0;
	If NewValueQuantity = 0 Then
		Object.AllocatedGoods.Delete(LineGoodsDistributed);
	Else
		LineGoodsDistributed.QuantityIsAllocated = NewValueQuantity;
	EndIf;
		
EndProcedure

&AtServer
Procedure SetDisplayOfTitleAndControls()
	
	CurrentPage = Items.MainPanel.CurrentPage;
	
	PageTitles = New Map;
	PageTitles.Insert(Items.SettingsPage,			 		NStr("vi = 'Tùy chỉnh.';
																	|ru = 'Настройка.';
																	|en = 'Setup.'; fa = 'Setup.';
																	|it = 'Impostazione.';
																	|pl = 'Setup.';
																	|tr = 'Ayarlar.'"));
	If GetFunctionalOption("UseGoodsQuality") Then
		PageTitles.Insert(Items.PageReSortingDamage,		NStr("vi = 'Tính lại do chuyển tồn và hàng hỏng.';
																|ru = 'Зачет по пересортице и порче.';
																|en = 'Reclass stock or change quality.'; fa = 'Reclass stock or change quality.';
																|it = 'La compensazione per riclassificazione e deterioramento.';
																|pl = 'Zaliczenie przeklasyfikowania i uszkodzenia.';
																|tr = 'Sıralama ve stok kalite değişikliğine göre denkleştirme.'"));
	Else
		PageTitles.Insert(Items.PageReSortingDamage,		NStr("vi = 'Tính lại do chuyển tồn.';
																|ru = 'Зачет по пересортице.';
																|en = 'Record by stock reclass.'; fa = 'Record by stock reclass.';
																|it = 'La compensazione per riclassificazione.';
																|pl = 'Zaliczenie przeklasyfikowania.';
																|tr = 'Yeniden sınıflandırmaya göre mahsup.'"));
	EndIf;
	PageTitles.Insert(Items.OrganizationDistributionPage,	NStr("vi = 'Phân bổ theo doanh nghiệp.';
																	|ru = 'Распределение по организациям.';
																	|en = 'Assign company stock for adjustment.'; fa = 'Assign company stock for adjustment.';
																	|it = 'Ripartizione per società.';
																	|pl = 'Podział według firmy.';
																	|tr = 'İş yerlerine göre dağıtım.'"));
	PageTitles.Insert(Items.DocumentProcessingPage,		NStr("vi = 'Lập biên bản.';
																|ru = 'Проведение актов.';
																|en = 'Review generated inventory adjustment documents.'; fa = 'Review generated inventory adjustment documents.';
																|it = 'Registrazione atti.';
																|pl = 'Zatwierdzenie aktów.';
																|tr = 'Düzeltmelerin kaydı.'"));
	Items.DecorationPageTitle.Title = PageTitles[CurrentPage];
	
	Items.ButtonsOnTheLeft.CurrentPage = ?(CurrentPage = Items.SettingsPage,
																Items.GroupOfButtonsOnTheLeftNone,
																Items.TheButtonGroupOnTheLeftIs);
	

	If CurrentPage = Items.DocumentProcessingPage Then
		Items.ButtonsOnTheRight.CurrentPage   = Items.GroupOfButtonsOnTheRightOnTheLastPage;
		Items.ConfirmButton.DefaultButton = True;
	Else
		Items.ButtonsOnTheRight.CurrentPage  = Items.GroupOfButtonsOnTheRightSideOfTheFirstPage;
		Items.NextButton.DefaultButton = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure DistributeOperationToOrganizationServer(TableRow, Organization, StringDistribution = Undefined)
	
	RowID = TableRow.GetID();
	
	Filter       = New Structure("ConnectionKey, Organization", RowID, Organization);
	RowsArray = Object.AllocatedGoods.FindRows(Filter);
	
	If RowsArray.Count() = 0 Then
		String = Object.AllocatedGoods.Add();
		FillPropertyValues(String, TableRow, , "QuantityIsAllocated");
		FillPropertyValues(String, Filter);
	Else
		String = RowsArray[0];
	EndIf;
	
	If StringDistribution = Undefined Then 
		QuantityToDistribution = Min(TableRow.Count, TableRow.QuantityNotAllocated);
		
		String.QuantityIsAllocated = String.QuantityIsAllocated + QuantityToDistribution;
		
		TableRow.QuantityIsAllocated   = TableRow.QuantityIsAllocated + QuantityToDistribution;
		TableRow.QuantityNotAllocated = TableRow.QuantityNotAllocated - QuantityToDistribution;
		
		TableRow.Allocated   = Not TableRow.QuantityIsAllocated = 0;
		TableRow.NotAllocated = Not TableRow.QuantityNotAllocated = 0;
	Else
		String.QuantityIsAllocated = String.QuantityIsAllocated + StringDistribution.QuantityIsAllocated;
		
		TableRow.Allocated   = Not TableRow.QuantityIsAllocated = 0;
		TableRow.NotAllocated = Not TableRow.QuantityNotAllocated = 0;
	EndIf;
	
EndProcedure

&AtServer
Function DataToDistribution()
	
	ArrayOfDistributableStrings = New Array;
	
	For Each Id In Items.ProductsNotDistributed.SelectedRows Do
		ArrayOfDistributableStrings.Add(Object.Goods.FindByID(Id));
	EndDo;
	
	TempTablesManager    = New TempTablesManager;
	TableOfAllocatedRows = Object.Goods.Unload(ArrayOfDistributableStrings);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Goods", TableOfAllocatedRows);
	Query.SetParameter("Warehouse",  Object.Warehouse);
	
	Query.Text =
	"SELECT
	|	Goods.ProductsWrittenOff   AS Products,
	|	Goods.ItemVariantOfGoodsIssue AS Characteristic,
	|	Goods.AssignmentOfWrittingOff     AS Purpose,
	|	Goods.WrittenOffBatch          AS Series,
	|	&Warehouse                           AS Warehouse
	|INTO ProductsDebited
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.QuantityNotAllocated > 0
	|	AND NOT Goods.ProductsWrittenOff = VALUE(Catalog.Products.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.ProductsRecordedAsReceived   AS Products,
	|	Goods.ItemVariantOfGoodsReceipt AS Characteristic,
	|	Goods.AssignmentRecordedAsReceived     AS Purpose,
	|	Goods.RecordedAsReceivedBatch          AS Series,
	|	&Warehouse                           AS Warehouse
	|INTO IncomingGoods_
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.QuantityNotAllocated > 0
	|	AND NOT Goods.ProductsRecordedAsReceived = VALUE(Catalog.Products.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose     AS Purpose,
	|	Goods.Series          AS Series,
	|	Goods.Warehouse          AS Warehouse,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	Dimension.DimensionKey AS ItemsLocationAttributes
	|INTO TableOfGoods
	|FROM
	|	(SELECT
	|		ProductsDebited.Products   AS Products,
	|		ProductsDebited.Characteristic AS Characteristic,
	|		ProductsDebited.Purpose     AS Purpose,
	|		ProductsDebited.Series          AS Series,
	|		ProductsDebited.Warehouse          AS Warehouse
	|	FROM
	|		ProductsDebited AS ProductsDebited
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		IncomingGoods_.Products   AS Products,
	|		IncomingGoods_.Characteristic AS Characteristic,
	|		IncomingGoods_.Purpose     AS Purpose,
	|		IncomingGoods_.Series          AS Series,
	|		IncomingGoods_.Warehouse          AS Warehouse
	|	FROM
	|		IncomingGoods_ AS IncomingGoods_) AS Goods
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Goods.Products = Dimension.Products
	|			AND Goods.Characteristic = Dimension.Characteristic
	|			AND Goods.Series = Dimension.Series
	|			AND Goods.Warehouse = Dimension.StorageLocation
	|			AND Goods.Purpose = Dimension.Purpose
	|			AND Dimension.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|
	|INDEX BY
	|	ItemsLocationAttributes";
	
	QueryResult = Query.Execute();
	
	DateOfRemainingGoods      = ?(WarehouseActDate = Date(1, 1, 1),
							CurrentSessionDate(),
							WarehouseActDate);
	CompaniesList = Object.SelectedCompanies.Unload().UnloadColumn("Organization");
	
	DocumentObject = New Structure();
	DocumentObject.Insert("Ref",      Undefined);
	DocumentObject.Insert("Date",        DateOfRemainingGoods);
	DocumentObject.Insert("Organization", CompaniesList);
	DocumentObject.Insert("Warehouse",       Object.Warehouse);
	DocumentObject.Insert("Posted",    False);
	DocumentObject.Insert("AdditionalProperties", New Structure());
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
	ParametersForFillingInventoryTypes.CompanyFieldName1 = "Organization";
	ParametersForFillingInventoryTypes.SelectTypesOfStocksForIntercampany = True;
	
	Filters = ParametersForFillingInventoryTypes.SelectionOfStockTypes_;
	Filters.Organization = DocumentObject[ParametersForFillingInventoryTypes.CompanyFieldName1];
	
	InventoriesServer.PrepareDataForReport(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes);
	InventoriesServer.GenerateTTTableOfBalances("CompanyGoods", DocumentObject, TempTablesManager,
		ParametersForFillingInventoryTypes, False);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	BalanceTable.Organization    AS Organization,
	|	BalanceTable.Products   AS Products,
	|	BalanceTable.Characteristic AS Characteristic,
	|	BalanceTable.Purpose     AS Purpose,
	|	BalanceTable.Series          AS Series,
	|	SUM(BalanceTable.CountBalance) AS CountBalance,
	|	SUM(BalanceTable.CountBalance) AS NumberOfRemainderGivenDistributions
	|FROM
	|	BalanceTable AS BalanceTable
	|WHERE
	|	BalanceTable.Organization IN(&Companies)
	|
	|GROUP BY
	|	BalanceTable.Organization,
	|	BalanceTable.Products,
	|	BalanceTable.Characteristic,
	|	BalanceTable.Purpose,
	|	BalanceTable.Series";
	
	Query.SetParameter("Companies", CompaniesList);
	
	BalanceTable = Query.Execute().Unload();
	
	// In the table of statistics, fill in the details of the number of statistics with the account of distributions
	For Each String In Object.AllocatedGoods Do
		Filter = New Structure;
		Filter.Insert("Organization", String.Organization);
		
		If String.TransactionText = "Damage"
			Or String.TransactionText = "Misgrading"
			Or String.TransactionText = "RecordingAsReceived" Then
			
			Filter.Insert("Products",		String.ProductsRecordedAsReceived);
			Filter.Insert("Characteristic",	String.ItemVariantOfGoodsReceipt);
			Filter.Insert("Purpose",		String.AssignmentRecordedAsReceived);
			Filter.Insert("Series",				String.RecordedAsReceivedBatch);
			
			RowsArray = BalanceTable.FindRows(Filter);
			
			If RowsArray.Count() > 0 Then
				RowsArray[0].NumberOfRemainderGivenDistributions =
					RowsArray[0].NumberOfRemainderGivenDistributions - String.QuantityIsAllocated;
			EndIf;
			
		EndIf;
		
		If String.TransactionText = "Damage"
			Or String.TransactionText = "Misgrading"
			Or String.TransactionText = "WriteOff" Then
			
			Filter.Insert("Products",		String.ProductsWrittenOff);
			Filter.Insert("Characteristic",	String.ItemVariantOfGoodsIssue);
			Filter.Insert("Purpose",		String.AssignmentOfWrittingOff);
			Filter.Insert("Series",				String.WrittenOffBatch);
			
			RowsArray = BalanceTable.FindRows(Filter);
			
			If RowsArray.Count() > 0 Then
				RowsArray[0].NumberOfRemainderGivenDistributions =
					RowsArray[0].NumberOfRemainderGivenDistributions - String.QuantityIsAllocated;
			EndIf;
			
		EndIf;
	EndDo;
	
	NumberType                      = New TypeDescription("Number", , , New NumberQualifiers(15, 3));
	StringType                     = New TypeDescription("String", , , , New StringQualifiers(15));
	TypeProducts               = New TypeDescription("CatalogRef.Products");
	TypeOfProductCharacteristics = New TypeDescription("CatalogRef.ItemsCharacteristics");
	AssignmentType                 = New TypeDescription("CatalogRef.Assignments");
	ProductSeriesType          = New TypeDescription("CatalogRef.ItemsBatches");
	TypeOfOrganization                = New TypeDescription("CatalogRef.Companies");
	
	DistributionTable_ = New ValueTable;
	DistributionTable_.Columns.Add("TransactionText",             StringType);
	DistributionTable_.Columns.Add("ProductsWrittenOff",   TypeProducts);
	DistributionTable_.Columns.Add("ProductsRecordedAsReceived",   TypeProducts);
	DistributionTable_.Columns.Add("ItemVariantOfGoodsIssue", TypeOfProductCharacteristics);
	DistributionTable_.Columns.Add("ItemVariantOfGoodsReceipt", TypeOfProductCharacteristics);
	DistributionTable_.Columns.Add("AssignmentOfWrittingOff",     AssignmentType);
	DistributionTable_.Columns.Add("AssignmentRecordedAsReceived",     AssignmentType);
	DistributionTable_.Columns.Add("WrittenOffBatch",          ProductSeriesType);
	DistributionTable_.Columns.Add("RecordedAsReceivedBatch",          ProductSeriesType);
	DistributionTable_.Columns.Add("Organization",               TypeOfOrganization);
	DistributionTable_.Columns.Add("QuantityIsAllocated",    NumberType);
	
	Filter = New Structure("Products, Characteristic, Purpose, Series");
	
	For Each DistributableString In ArrayOfDistributableStrings Do
		If DistributableString.TransactionText = "RecordingAsReceived" Then
			Filter.Products = DistributableString.ProductsRecordedAsReceived;
			Filter.Characteristic = DistributableString.ItemVariantOfGoodsReceipt;
			Filter.Purpose = DistributableString.AssignmentRecordedAsReceived;
			Filter.Series = DistributableString.RecordedAsReceivedBatch;
			
			// We are looking for a line of the remaining goods that need to be registered.
			Balance = BalanceTable.FindRows(Filter);
			
			If Balance.Count() = 0
				And CompaniesList.Count() > 0 Then
				
				// If there is a balance greater than zero, then we will register the goods to this organization
				If DistributableString.QuantityNotAllocated > 0 Then
					
					StringDistribution = DistributionTable_.Add();
					FillPropertyValues(StringDistribution, DistributableString, , "QuantityIsAllocated");
					
					StringDistribution.Organization = CompaniesList[0];
					StringDistribution.QuantityIsAllocated = DistributableString.QuantityNotAllocated;
					
					DistributableString.QuantityNotAllocated = 0;
					DistributableString.QuantityIsAllocated = StringDistribution.QuantityIsAllocated;
					
					StringBalance = BalanceTable.Add();
					StringBalance.Organization = StringDistribution.Organization;
					
					StringBalance.Products = DistributableString.ProductsRecordedAsReceived;
					StringBalance.Characteristic = DistributableString.ItemVariantOfGoodsReceipt;
					StringBalance.Purpose = DistributableString.AssignmentRecordedAsReceived;
					StringBalance.Series = DistributableString.RecordedAsReceivedBatch;
					
					StringBalance.NumberOfRemainderGivenDistributions = StringDistribution.QuantityIsAllocated;
					
					Continue;
					
				EndIf;
				
			EndIf;
			
			For Each StringBalance In Balance Do
				
				// If there is a balance greater than zero, then we will register the goods to this organization
				If DistributableString.QuantityNotAllocated > 0 Then
					
					StringDistribution = DistributionTable_.Add();
					FillPropertyValues(StringDistribution, DistributableString, , "QuantityIsAllocated");
					
					StringDistribution.Organization = StringBalance.Organization;
					
					RemainsToAllocate = Min(StringBalance.NumberOfRemainderGivenDistributions,
						DistributableString.QuantityNotAllocated);
					
					StringDistribution.QuantityIsAllocated = RemainsToAllocate;
					StringBalance.NumberOfRemainderGivenDistributions = StringBalance.NumberOfRemainderGivenDistributions +
						StringDistribution.QuantityIsAllocated;
					
					DistributableString.QuantityNotAllocated = DistributableString.QuantityNotAllocated -
						StringDistribution.QuantityIsAllocated;
					DistributableString.QuantityIsAllocated = DistributableString.QuantityIsAllocated +
						StringDistribution.QuantityIsAllocated;
					
					If DistributableString.QuantityNotAllocated <= 0 Then
						Break;
					EndIf;
					
				EndIf;
				
			EndDo;
		Else
			Filter.Products = DistributableString.ProductsWrittenOff;
			Filter.Characteristic = DistributableString.ItemVariantOfGoodsIssue;
			Filter.Purpose = DistributableString.AssignmentOfWrittingOff;
			Filter.Series = DistributableString.WrittenOffBatch;
			
			// We are looking for the lines of the remaining goods that need to be written off
			Balance = BalanceTable.FindRows(Filter);
			
			For Each StringBalance In Balance Do
				
				// If the balance of the product being written off is greater than zero, we will write off everything we can
				If StringBalance.NumberOfRemainderGivenDistributions > 0 Then
					
					StringDistribution = DistributionTable_.Add();
					FillPropertyValues(StringDistribution, DistributableString, , "QuantityIsAllocated");
					
					StringDistribution.Organization = StringBalance.Organization;
					
					StringDistribution.QuantityIsAllocated = 
						?(StringBalance.NumberOfRemainderGivenDistributions > DistributableString.QuantityNotAllocated,
							DistributableString.QuantityNotAllocated, StringBalance.NumberOfRemainderGivenDistributions);
					
					StringBalance.NumberOfRemainderGivenDistributions = StringBalance.NumberOfRemainderGivenDistributions -
						StringDistribution.QuantityIsAllocated;
					
					DistributableString.QuantityNotAllocated = DistributableString.QuantityNotAllocated -
						StringDistribution.QuantityIsAllocated;
					DistributableString.QuantityIsAllocated = DistributableString.QuantityIsAllocated +
						StringDistribution.QuantityIsAllocated;
					
					If DistributableString.QuantityNotAllocated <= 0 Then
						Break;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
	EndDo;
	
	Return DistributionTable_;
	
EndFunction

&AtServer
Procedure RegisterWarehouseActsServer()
	
	ShouldSaveSettingsServer();
	
	WarehouseActs.Clear();
	
	ArrayOfTypesOfOperations = New Array;
	ArrayOfTypesOfOperations.Add("RecordingAsReceived");
	ArrayOfTypesOfOperations.Add("Damage");
	ArrayOfTypesOfOperations.Add("Misgrading");
	ArrayOfTypesOfOperations.Add("WriteOff");
	
	DocumentDate = ?(WarehouseActDate = Date(1, 1, 1),
				CurrentSessionDate(),
				WarehouseActDate);
	
	For Each OperationKind In ArrayOfTypesOfOperations Do
		Filteroperations  = New Structure("TransactionText", OperationKind);
		OperationArray = Object.AllocatedGoods.FindRows(Filteroperations);
		Operations       = Object.AllocatedGoods.Unload(OperationArray);
		
		OrganizationOfOperations = Operations.UnloadColumn("Organization");
		Companies         = CommonClientServer.CollapseArray(OrganizationOfOperations);
		
		For Each Organization In Companies Do 
			Filter = New Structure("Organization, TransactionText", Organization, OperationKind);
			
			If OperationKind = "RecordingAsReceived" Then
				DocumentRef = CreateAccountOfSurplusGoodsServer(Organization, DocumentDate, Operations.FindRows(Filter));
				WarehouseActs.Add(DocumentRef);
			ElsIf OperationKind = "Damage" Then
				DocumentRef = CreateGoodsSpoilageServer(Organization, DocumentDate, Operations.FindRows(Filter));
				WarehouseActs.Add(DocumentRef);
			ElsIf OperationKind = "Misgrading" Then
				DocumentRef = CreateProductResortmentServer(Organization, DocumentDate, Operations.FindRows(Filter));
				WarehouseActs.Add(DocumentRef);
			ElsIf OperationKind = "WriteOff" Then
				DocumentRef = CreateWriteOffOfShortageOfGoodsServer(Organization, DocumentDate, Operations.FindRows(Filter));
				WarehouseActs.Add(DocumentRef);
			EndIf;
		EndDo;
	EndDo;
	
	StocktakingSheets.Clear();
	
	CompanyTable = Object.AllocatedGoods.Unload(,"Organization");
	CompanyTable.GroupBy("Organization");
	
	For Each Organization In CompanyTable.UnloadColumn("Organization") Do
		DocumentObject = Documents.PhysicalCountReport.CreateDocument();
		DocumentObject.Date = WarehouseActDate;
		DocumentObject.Organization = Organization;
		DocumentObject.Warehouse = Object.Warehouse;
		DocumentObject.SourseOfInformationAboutPricesForPrinting = Object.SourseOfInformationAboutPricesForPrinting;
		DocumentObject.PriceKind = Object.PriceKind;
		DocumentObject.StartDate = StocktakingPeriod.StartDate;
		DocumentObject.EndDate = StocktakingPeriod.EndDate;
		DocumentObject.Write();
		
		If DocumentObject.CheckFilling() Then
			DocumentObject.Write(DocumentWriteMode.Posting, DocumentPostingMode.Regular);
		EndIf;
		
		StocktakingSheets.Add(DocumentObject.Ref);
	EndDo;
	
	WarehouseActsArray = WarehouseActs.UnloadValues();
	
	For Each PhysicalCountReport In StocktakingSheets.UnloadValues() Do
		WarehouseActsArray.Add(PhysicalCountReport);
	EndDo;
	
	CommonClientServer.SetDynamicListFilterItem(DocumentsByBasis,
										"Ref",
										WarehouseActsArray,
										DataCompositionComparisonType.InList,
										,
										True);
	
EndProcedure

&AtServer
Function CreateWriteOffOfShortageOfGoodsServer(Val Organization, Val DocumentDate, Val DistributionLines)
	
	DocumentObject = Documents.WriteOffOfGoodsShortages.CreateDocument();
	FillingData = FillingDataStructure(Organization, DocumentDate);
	DocumentObject.Fill(FillingData);
	
	For Each Allocation In DistributionLines Do
		NewRow = DocumentObject.Goods.Add();
		FillPropertyValues(NewRow, Allocation);
		NewRow.Products = Allocation.ProductsWrittenOff;
		NewRow.Characteristic = Allocation.ItemVariantOfGoodsIssue;
		NewRow.Purpose = Allocation.AssignmentOfWrittingOff;
		NewRow.Series = Allocation.WrittenOffBatch;
		NewRow.Count = Allocation.QuantityIsAllocated;
	EndDo;
	
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(DocumentObject,
			Documents.WriteOffOfGoodsShortages));
			
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
	
	If ValueIsFilled(DocumentObject.PriceKind) And DocumentObject.Goods.Count() > 0 Then
		
		ColumnsByValue = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		
		FillParameters = New Structure;
		FillParameters.Insert("Date", DocumentObject.Date);
		FillParameters.Insert("Currency", Constants.ManagementAccountingCurrency.Get());
		FillParameters.Insert("PriceKind", DocumentObject.PriceKind);
		FillParameters.Insert("ColumnsByValue", ColumnsByValue);
		FillParameters.Insert("Organization", Organization);
		
		EnterprisePricesFillingServer.FillInPrices(
			DocumentObject.Goods, ,
			FillParameters,
			New Structure()
			);
	EndIf;
	
	RecordWarehouseReport(DocumentObject);
	
	For Each Allocation In DistributionLines Do
		Allocation.Document = DocumentObject.Ref;
	EndDo;
	
	Return DocumentObject.Ref;
	
EndFunction

&AtServer
Function CreateProductResortmentServer(Val Organization, Val DocumentDate, Val DistributionLines)
	
	DocumentObject = Documents.GoodsMisgrading.CreateDocument();
	FillingData = FillingDataStructure(Organization, DocumentDate);
	DocumentObject.Fill(FillingData);
	
	For Each Allocation In DistributionLines Do
		NewRow = DocumentObject.Goods.Add();
		FillPropertyValues(NewRow, Allocation);
		NewRow.Products = Allocation.ProductsWrittenOff;
		NewRow.Characteristic = Allocation.ItemVariantOfGoodsIssue;
		NewRow.Purpose = Allocation.AssignmentOfWrittingOff;
		NewRow.Series = Allocation.WrittenOffBatch;
		NewRow.ProductsRecordingAsReceived = Allocation.ProductsRecordedAsReceived;
		NewRow.CharacteristicRecordingAsReceived = Allocation.ItemVariantOfGoodsReceipt;
		NewRow.AssignmentGoodsReceipt = Allocation.AssignmentRecordedAsReceived;
		NewRow.BatchReceipt = Allocation.RecordedAsReceivedBatch;
		NewRow.Count = Allocation.QuantityIsAllocated;
	EndDo;
	
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(DocumentObject,
			Documents.GoodsMisgrading));
			
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
	
	If ValueIsFilled(DocumentObject.PriceKind) And DocumentObject.Goods.Count() > 0 Then
		
		ColumnsByValue = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		OtherColumnNames = New Structure("ProductsRecordingAsReceived, CharacteristicRecordingAsReceived", "Products", "Characteristic");
		
		FillParameters = New Structure;
		FillParameters.Insert("Date", DocumentObject.Date);
		FillParameters.Insert("Currency", Constants.ManagementAccountingCurrency.Get());
		FillParameters.Insert("PriceKind", DocumentObject.PriceKind);
		FillParameters.Insert("Organization", Organization);
		FillParameters.Insert("ColumnsByValue", ColumnsByValue);
		FillParameters.Insert("OtherColumnNames", OtherColumnNames);
		
		EnterprisePricesFillingServer.FillInPrices(
			DocumentObject.Goods, // Table part
			, // Selected lines (fill in all lines)
			FillParameters);

	EndIf;
	
	RecordWarehouseReport(DocumentObject);
	
	For Each Allocation In DistributionLines Do
		Allocation.Document = DocumentObject.Ref;
	EndDo;
	
	Return DocumentObject.Ref;
	
EndFunction

&AtServer
Function CreateGoodsSpoilageServer(Val Organization, Val DocumentDate, Val DistributionLines)
	
	DocumentObject = Documents.GoodsDamage.CreateDocument();
	FillingData = FillingDataStructure(Organization, DocumentDate);
	DocumentObject.Fill(FillingData);
	
	For Each Allocation In DistributionLines Do
		
		NewRow = DocumentObject.Goods.Add();
		FillPropertyValues(NewRow, Allocation);
		
		NewRow.Products = Allocation.ProductsWrittenOff;
		NewRow.Characteristic = Allocation.ItemVariantOfGoodsIssue;
		NewRow.Purpose = Allocation.AssignmentOfWrittingOff;
		NewRow.ProductsRecordingAsReceived = Allocation.ProductsRecordedAsReceived;
		NewRow.CharacteristicRecordingAsReceived = Allocation.ItemVariantOfGoodsReceipt;
		NewRow.ForAssignment = ValueIsFilled(Allocation.AssignmentRecordedAsReceived);
		NewRow.Series = Allocation.WrittenOffBatch;
		NewRow.Count = Allocation.QuantityIsAllocated;
		
	EndDo;
	
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(DocumentObject,
			Documents.GoodsDamage));
			
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
	
	If ValueIsFilled(DocumentObject.PriceKind) And DocumentObject.Goods.Count() > 0 Then
		
		ColumnsByValue = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		OtherColumnNames = New Structure("ProductsRecordingAsReceived, CharacteristicRecordingAsReceived", "Products", "Characteristic");
		
		FillParameters = New Structure;
		FillParameters.Insert("Date", DocumentObject.Date);
		FillParameters.Insert("Currency", Constants.ManagementAccountingCurrency.Get());
		FillParameters.Insert("PriceKind", DocumentObject.PriceKind);
		FillParameters.Insert("Organization", Organization);
		FillParameters.Insert("ColumnsByValue", ColumnsByValue);
		FillParameters.Insert("OtherColumnNames", OtherColumnNames);
		
		EnterprisePricesFillingServer.FillInPrices(
			DocumentObject.Goods, // Table part
			, // Selected lines (fill in all lines)
			FillParameters);
		
	EndIf;
	
	RecordWarehouseReport(DocumentObject);
	
	For Each Allocation In DistributionLines Do
		Allocation.Document = DocumentObject.Ref;
	EndDo;
	
	Return DocumentObject.Ref;
	
EndFunction

&AtServer
Function CreateAccountOfSurplusGoodsServer(Val Organization, Val DocumentDate, Val DistributionLines)
	
	DocumentObject = Documents.InventorySurplusRecognition.CreateDocument();
	FillingData = FillingDataStructure(Organization, DocumentDate);
	DocumentObject.Fill(FillingData);	
	
	For Each Allocation In DistributionLines Do
		
		NewRow = DocumentObject.Goods.Add();
		FillPropertyValues(NewRow, Allocation);
		
		NewRow.Products = Allocation.ProductsRecordedAsReceived;
		NewRow.Characteristic = Allocation.ItemVariantOfGoodsReceipt;
		NewRow.Purpose = Allocation.AssignmentRecordedAsReceived;
		NewRow.Series = Allocation.RecordedAsReceivedBatch;
		NewRow.Count = Allocation.QuantityIsAllocated;
		
		NewRow.Sum = NewRow.Count * NewRow.Price;
		
	EndDo;
	
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(DocumentObject,
			Documents.InventorySurplusRecognition));
			
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
	
	If ValueIsFilled(DocumentObject.PriceKind) And DocumentObject.Goods.Count() > 0 Then
		
		ColumnsByValue = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		
		FillParameters = New Structure;
		FillParameters.Insert("Date", DocumentObject.Date);
		FillParameters.Insert("Currency", Constants.ManagementAccountingCurrency.Get());
		FillParameters.Insert("PriceKind", DocumentObject.PriceKind);
		FillParameters.Insert("Organization", Organization);
		FillParameters.Insert("ColumnsByValue", ColumnsByValue);
		
		Actions = New Structure("RecalculateAmount", "Count");
		
		EnterprisePricesFillingServer.FillInPrices(DocumentObject.Goods,, FillParameters, Actions);
		
	EndIf;
	
	RecordWarehouseReport(DocumentObject);
	
	For Each Allocation In DistributionLines Do
		Allocation.Document = DocumentObject.Ref;
	EndDo;
	
	Return DocumentObject.Ref;
	
EndFunction

&AtServer
Procedure RecordWarehouseReport(WarehouseReport)
	
	WarehouseReport.Write(DocumentWriteMode.Write);
	If WarehouseReport.CheckFilling() Then
		Try
			WarehouseReport.Write(DocumentWriteMode.Posting, DocumentPostingMode.Regular);
		Except
			PresentationOfDocument = String(WarehouseReport.Ref);
			DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
			
			MessageText = NStr("vi = 'Không thể kết chuyển chứng từ ""%Document%"".';
								|ru = 'Не удалось провести документ ""%Document%"".';
								|en = 'Cannot post the ""%Document%"" document.'; fa = 'Cannot post the ""%Document%"" document.';
								|it = 'Impossibile registrare il documento ""%Document%"".';
								|pl = 'Nie udało się zatwierdzić dokument ""%Document%"".';
								|tr = '""%Document%"" belge kaydedilemedi.'");
			MessageText = StrReplace(MessageText, "%Document%", PresentationOfDocument);
			
			CommonClientServer.MessageToUser(MessageText, WarehouseReport.Ref);
			WriteLogEvent(NStr("vi = 'Lập biên bản kho bãi';
								|ru = 'Оформление складских актов';
								|en = 'Inventory adjustments'; fa = 'تعدیل‌های موجودی';
								|it = 'Formalizzazione degli atti di magazzino';
								|pl = 'Rejestracja akt magazynowych';
								|tr = 'Stok düzeltmelerinin düzenlenmesi'", DefaultLanguageCode),
				EventLogLevel.Error, , ,
				DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteWarehouseReportsInventoryInventoriesServer()
		
	SetPrivilegedMode(True);
	
	For Each Document In WarehouseActs Do
		DocumentObject = Document.Value.GetObject();
		DocumentObject.SetDeletionMark(True);
	EndDo;
	
	For Each Document In StocktakingSheets Do
		DocumentObject = Document.Value.GetObject();
		DocumentObject.SetDeletionMark(True);
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure PrepareProductTableForOperation()
	
	// getting a list of products
	ProductsTable = DataProcessors.WarehouseGoodsIssueReceiptWizard.GoodsForRegistrationOfWarehouseActs(Object.Warehouse, FilterOfProductItem, StocktakingPeriod.StartDate, StocktakingPeriod.EndDate);
	ProductsTable.Columns.Add("FilterFlag", New TypeDescription("Boolean"));
	For Each String In ProductsTable Do
		String.FilterFlag = Not SelectByOperationType.FindByValue(String.TransactionText) = Undefined;
	EndDo;
	
	// filling in their prices
	If ValueIsFilled(Object.PriceKind) Then
		ProductsTable.Columns.Add("PriceOfPurchaseInvoice", TMCommonUse.MoneyFieldTypeDescription());
		ProductsTable.Columns.Add("PriceOfGoodsIssue", TMCommonUse.MoneyFieldTypeDescription());
		
		QueryText =
		"SELECT
		|	TableOfGoods.ProductsWrittenOff,
		|	TableOfGoods.ItemVariantOfGoodsIssue,
		|	TableOfGoods.AssignmentOfWrittingOff,
		|	TableOfGoods.ProductsRecordedAsReceived,
		|	TableOfGoods.ItemVariantOfGoodsReceipt,
		|	TableOfGoods.AssignmentRecordedAsReceived
		|INTO TableOfGoods
		|FROM
		|	&TableOfGoods AS TableOfGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TableOfGoods.Products,
		|	TableOfGoods.Characteristic,
		|	TableOfGoods.Purpose
		|INTO Goods
		|FROM
		|	(SELECT
		|		TableOfGoods.ProductsWrittenOff AS Products,
		|		TableOfGoods.ItemVariantOfGoodsIssue AS Characteristic,
		|		TableOfGoods.AssignmentOfWrittingOff AS Purpose
		|	FROM
		|		TableOfGoods AS TableOfGoods
		|	WHERE
		|		NOT TableOfGoods.ProductsWrittenOff = &EmptyItemList
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableOfGoods.ProductsRecordedAsReceived,
		|		TableOfGoods.ItemVariantOfGoodsReceipt,
		|		TableOfGoods.AssignmentRecordedAsReceived
		|	FROM
		|		TableOfGoods AS TableOfGoods
		|	WHERE
		|		NOT TableOfGoods.ProductsRecordedAsReceived = &EmptyItemList) AS TableOfGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ItemPricesCrossSectionOfTheLatest.Products,
		|	ItemPricesCrossSectionOfTheLatest.Characteristic,
		|	CASE
		|		WHEN NOT &QueryTextPackagingFactor IS NULL 
		|				AND &QueryTextPackagingFactor <> 0
		|			THEN ItemPricesCrossSectionOfTheLatest.Price / &QueryTextPackagingFactor
		|		ELSE ItemPricesCrossSectionOfTheLatest.Price
		|	END AS Price
		|FROM
		|	InformationRegister.ItemsPrices.SliceLast(
		|			&WarehouseActDate,
		|			PriceKind = &PriceKind
		|				AND (Products, Characteristic) IN
		|					(SELECT
		|						Goods.Products,
		|						Goods.Characteristic
		|					FROM
		|						Goods AS Goods)) AS ItemPricesCrossSectionOfTheLatest";
		QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));

		Query = New Query;
		Query.SetParameter("PriceKind", Object.PriceKind);
		Query.SetParameter("TableOfGoods", ProductsTable);
		Query.SetParameter("EmptyItemList", Catalogs.Products.EmptyRef());
		Query.SetParameter("WarehouseActDate", WarehouseActDate);
		Query.Text = QueryText;
		Price_Table = Query.Execute().Unload();
		For Each PriceTableRow In Price_Table Do
			If PriceTableRow.Price = 0 Then
				Continue;
			EndIf;
			
			ArrayOfProducts_2 = ProductsTable.FindRows(New Structure("ProductsRecordedAsReceived,ItemVariantOfGoodsReceipt", 
				PriceTableRow.Products, PriceTableRow.Characteristic));
				
			For Each String In ArrayOfProducts_2 Do
				String.PriceOfPurchaseInvoice = PriceTableRow.Price;
			EndDo;
			
			ArrayOfProducts_2 = ProductsTable.FindRows(New Structure("ProductsWrittenOff,ItemVariantOfGoodsIssue", 
				PriceTableRow.Products, PriceTableRow.Characteristic));
				
			For Each String In ArrayOfProducts_2 Do
				String.PriceOfGoodsIssue = PriceTableRow.Price;
			EndDo;
		EndDo;
	EndIf;
	
	// loading into the tabular part
	Object.Goods.Load(ProductsTable);
	Object.AllocatedGoods.Clear();
	
	// visibility of the "Series" column
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	Items.GoodsToWriteOffWrittenOffBatch.Visible = WarehouseSeriesParameters.UseItemsBatch;
	Items.GoodsToRecordAsReceivedRecordedAsReceivedBatch.Visible = WarehouseSeriesParameters.UseItemsBatch;
	Items.GoodsToBeReSortedToBeDamagedSeriesDebited.Visible = WarehouseSeriesParameters.UseItemsBatch;
	Items.GoodsToBeReSortedToBeDamagedSeriesReceived.Visible = WarehouseSeriesParameters.UseItemsBatch;
	Items.GoodsAreNotDistributedSeriesWrittenOff.Visible = WarehouseSeriesParameters.UseItemsBatch;
	Items.GoodsAreNotDistributedSeriesToBeCapitalized.Visible = WarehouseSeriesParameters.UseItemsBatch;
	Items.AllocatedGoodsWrittenOffBatch.Visible = WarehouseSeriesParameters.UseItemsBatch;
	Items.AllocatedGoodsRecordedAsReceivedBatch.Visible = WarehouseSeriesParameters.UseItemsBatch;
	
	// preparing the selection of lines for the design of re-sorting and spoilage
	GenerateListOfMatchingItemsServer();
	
	// loading distribution settings
	LoadSettingsServer();
	
	SetDisplayOfTitleAndControls();
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	// getting warehouse data
	If ValueIsFilled(Object.Warehouse) Then
		GoodsQuantityToRegister = GetNumberOfProductsToBeProcessed(True);
		GoodsQuantityToRegisterWithFilterTakenIntoAccount = GetNumberOfProductsToBeProcessed(False);
		
		CheckBoxThereAreIncompleteRecountsInTheWarehouse = ThereAreUnformulatedWarehouseRecalculationsServer(Object.Warehouse);
				
	Else
		CheckBoxThereAreIncompleteRecountsInTheWarehouse = False;
	EndIf;
	
	// filling in the default price view
	Object.SourseOfInformationAboutPricesForPrinting = Catalogs.Warehouses.SourseOfInformationAboutPricesForPrinting(Object.Warehouse);
	SourceOfPricingInformationToPrintWhenChangedOnServer();
	SetDisplayByWarehouse();
	
EndProcedure

&AtServer
Procedure SourceOfPricingInformationToPrintWhenChangedOnServer()
	
	SourseOfInformationAboutPricesForPrinting = Object.SourseOfInformationAboutPricesForPrinting;
	SetPriceViewValueServer(SourseOfInformationAboutPricesForPrinting);
	SetNewKindOfPriceServer(SourseOfInformationAboutPricesForPrinting);
	
EndProcedure

&AtServer
Procedure CreateNewRowByOffsetServer(ProductsDebitedLine, IncomingGoodsLine_, Val Operation, Val Count)
	
	// creating a credit
	Filter = New Structure("TransactionText,ProductsWrittenOff,ItemVariantOfGoodsIssue,AssignmentOfWrittingOff,WrittenOffBatch,VATRate,
		|PriceOfGoodsIssue,ProductsRecordedAsReceived,ItemVariantOfGoodsReceipt,AssignmentRecordedAsReceived,RecordedAsReceivedBatch,PriceOfPurchaseInvoice");
	FillPropertyValues(Filter, ProductsDebitedLine, 
		"ProductsWrittenOff,ItemVariantOfGoodsIssue,AssignmentOfWrittingOff,WrittenOffBatch,VATRate,PriceOfGoodsIssue");
	FillPropertyValues(Filter, IncomingGoodsLine_, 
		"ProductsRecordedAsReceived,ItemVariantOfGoodsReceipt,AssignmentRecordedAsReceived,RecordedAsReceivedBatch,PriceOfPurchaseInvoice");
	Filter.TransactionText = Operation;
	RowsArray = Object.Goods.FindRows(Filter);
	If RowsArray.Count() = 0 Then
		String = Object.Goods.Add();
	Else
		String = RowsArray[0];
	EndIf;
	FillPropertyValues(String, Filter);
	String.TransactionText = Operation;
	String.OperationDamage = String.TransactionText = "Damage";
	String.MisgradingOperation = Not String.OperationDamage;
	String.DamageMisgradingOperation = True; 
	String.Count = String.Count + Count;
	String.QuantityNotAllocated = String.QuantityNotAllocated + Count;
	String.NotAllocated = Not String.QuantityNotAllocated = 0;
	String.Allocated = Not String.QuantityIsAllocated = 0;
	String.FilterFlag = Not SelectByOperationType.FindByValue(String.TransactionText) = Undefined;
	
	// we clean the creditable receipt
	If IncomingGoodsLine_.QuantityNotAllocated < Count Then
		ArrayOfRowsToDelete = Object.AllocatedGoods.FindRows(
			New Structure("ConnectionKey", IncomingGoodsLine_.GetID()));
			
		For Each RowForDeletion In ArrayOfRowsToDelete Do
			Object.AllocatedGoods.Delete(RowForDeletion);
		EndDo;
		IncomingGoodsLine_.QuantityNotAllocated = IncomingGoodsLine_.QuantityNotAllocated 
			+ IncomingGoodsLine_.QuantityIsAllocated;
		IncomingGoodsLine_.QuantityIsAllocated = 0;
	EndIf;
	IncomingGoodsLine_.Count = IncomingGoodsLine_.Count - Count;
	IncomingGoodsLine_.QuantityNotAllocated = IncomingGoodsLine_.QuantityNotAllocated - Count; 
	IncomingGoodsLine_.NotAllocated = Not IncomingGoodsLine_.QuantityNotAllocated = 0;
	IncomingGoodsLine_.Allocated = Not IncomingGoodsLine_.QuantityIsAllocated = 0;
	
	// we clean the read- out , write-off
	If ProductsDebitedLine.QuantityNotAllocated < Count Then
		ArrayOfRowsToDelete = Object.AllocatedGoods.FindRows(
			New Structure("ConnectionKey", ProductsDebitedLine.GetID()));
			
		For Each RowForDeletion In ArrayOfRowsToDelete Do
			Object.AllocatedGoods.Delete(RowForDeletion);
		EndDo;
		ProductsDebitedLine.QuantityNotAllocated = ProductsDebitedLine.QuantityNotAllocated
			+ ProductsDebitedLine.QuantityIsAllocated;
		ProductsDebitedLine.QuantityIsAllocated = 0;
	EndIf;
	ProductsDebitedLine.Count					= ProductsDebitedLine.Count - Count;
	ProductsDebitedLine.QuantityNotAllocated	= ProductsDebitedLine.QuantityNotAllocated - Count; 
	ProductsDebitedLine.NotAllocated 				= Not ProductsDebitedLine.QuantityNotAllocated = 0;
	ProductsDebitedLine.Allocated				= Not ProductsDebitedLine.QuantityIsAllocated = 0;
	
EndProcedure

&AtServer
Function GetOptionsForScoringServerDamage()
	
	Query = New Query;
	Query.SetParameter("GoodsTable", Object.Goods.Unload());
	Query.Text =
	"SELECT
	|	GoodsTable.ProductsWrittenOff,
	|	GoodsTable.ItemVariantOfGoodsIssue,
	|	GoodsTable.AssignmentOfWrittingOff,
	|	GoodsTable.WrittenOffBatch
	|INTO TableForDebiting
	|FROM
	|	&GoodsTable AS GoodsTable
	|WHERE
	|	GoodsTable.TransactionText = ""WriteOff""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.ProductsRecordedAsReceived,
	|	GoodsTable.ItemVariantOfGoodsReceipt,
	|	GoodsTable.AssignmentRecordedAsReceived,
	|	GoodsTable.RecordedAsReceivedBatch,
	|	GoodsTable.QuantityNotAllocated AS Count
	|INTO TableForRegistration
	|FROM
	|	&GoodsTable AS GoodsTable
	|WHERE
	|	GoodsTable.TransactionText = ""RecordingAsReceived""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableForDebiting.ProductsWrittenOff,
	|	TableForDebiting.ItemVariantOfGoodsIssue,
	|	TableForDebiting.AssignmentOfWrittingOff,
	|	TableForDebiting.WrittenOffBatch,
	|	TableForRegistration.ProductsRecordedAsReceived,
	|	TableForRegistration.ItemVariantOfGoodsReceipt,
	|	TableForRegistration.AssignmentRecordedAsReceived,
	|	TableForRegistration.RecordedAsReceivedBatch
	|FROM
	|	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|		INNER JOIN TableForDebiting AS TableForDebiting
	|		ON (TableForDebiting.ProductsWrittenOff = AnotherQualityGoods.Products)
	|		INNER JOIN TableForRegistration AS TableForRegistration
	|		ON (TableForRegistration.ProductsRecordedAsReceived = AnotherQualityGoods.OtherQualityGoods)
	|WHERE
	|	ISNULL(CAST(TableForDebiting.WrittenOffBatch AS Catalog.ItemsBatches).Description, """") = ISNULL(CAST(TableForRegistration.RecordedAsReceivedBatch AS Catalog.ItemsBatches).Description, """")
	|	AND ISNULL(CAST(TableForDebiting.ItemVariantOfGoodsIssue AS Catalog.ItemsCharacteristics).Description, """") = ISNULL(CAST(TableForRegistration.ItemVariantOfGoodsReceipt AS Catalog.ItemsCharacteristics).Description, """")
	|	AND (ISNULL(CAST(TableForDebiting.AssignmentOfWrittingOff AS Catalog.Assignments).Description, """") = ISNULL(CAST(TableForRegistration.AssignmentRecordedAsReceived AS Catalog.Assignments).Description, """")
	|			OR (CAST(TableForRegistration.AssignmentRecordedAsReceived AS Catalog.Assignments)) = VALUE(Catalog.Assignments.EmptyRef))
	|
	|ORDER BY
	|	TableForDebiting.ProductsWrittenOff,
	|	TableForDebiting.ItemVariantOfGoodsIssue,
	|	TableForDebiting.WrittenOffBatch,
	|	TableForRegistration.AssignmentRecordedAsReceived DESC";
	
	Return Query.Execute().Unload();
		
EndFunction

&AtServer
Function GetOptionsForOffsettingByResortmentServer()
	
	Query = New Query;
	Query.SetParameter("GoodsTable", Object.Goods.Unload());
	Query.Text =
	"SELECT
	|	GoodsTable.ProductsWrittenOff,
	|	GoodsTable.ItemVariantOfGoodsIssue,
	|	GoodsTable.AssignmentOfWrittingOff,
	|	GoodsTable.WrittenOffBatch
	|INTO TableForDebiting
	|FROM
	|	&GoodsTable AS GoodsTable
	|WHERE
	|	GoodsTable.TransactionText = ""WriteOff""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.ProductsRecordedAsReceived,
	|	GoodsTable.ItemVariantOfGoodsReceipt,
	|	GoodsTable.AssignmentRecordedAsReceived,
	|	GoodsTable.RecordedAsReceivedBatch
	|INTO TableForRegistration
	|FROM
	|	&GoodsTable AS GoodsTable
	|WHERE
	|	GoodsTable.TransactionText = ""RecordingAsReceived""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableForDebiting.ProductsWrittenOff,
	|	TableForDebiting.ItemVariantOfGoodsIssue,
	|	TableForDebiting.AssignmentOfWrittingOff,
	|	TableForDebiting.WrittenOffBatch,
	|	TableForRegistration.ProductsRecordedAsReceived,
	|	TableForRegistration.ItemVariantOfGoodsReceipt,
	|	TableForRegistration.AssignmentRecordedAsReceived,
	|	TableForRegistration.RecordedAsReceivedBatch
	|FROM
	|	TableForDebiting AS TableForDebiting
	|		INNER JOIN TableForRegistration AS TableForRegistration
	|		ON TableForDebiting.ProductsWrittenOff = TableForRegistration.ProductsRecordedAsReceived
	|
	|ORDER BY
	|	TableForDebiting.ProductsWrittenOff,
	|	TableForDebiting.ItemVariantOfGoodsIssue,
	|	TableForDebiting.AssignmentOfWrittingOff,
	|	TableForDebiting.WrittenOffBatch,
	|	TableForRegistration.ProductsRecordedAsReceived,
	|	TableForRegistration.ItemVariantOfGoodsReceipt,
	|	TableForRegistration.AssignmentRecordedAsReceived,
	|	TableForRegistration.RecordedAsReceivedBatch";

	Return Query.Execute().Unload();
		
EndFunction

&AtServer
Procedure SetSelectionOfLinesByNomenclatureServer()
	
	If ValueIsFilled(PickProductsLines) Then
		Items.GoodsToRecordAsReceived.RowFilter = 
			New FixedStructure("GoodsReceiptTransaction,ProductsRecordedAsReceived,", True, PickProductsLines);
		Items.GoodsToWriteOff.RowFilter = 
			New FixedStructure("TransactionConsumption,ProductsWrittenOff,", True, PickProductsLines);
	Else
		Items.GoodsToWriteOff.RowFilter = 
			New FixedStructure("TransactionConsumption", True);
		Items.GoodsToRecordAsReceived.RowFilter = 
			New FixedStructure("GoodsReceiptTransaction", True);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDefaultValuesServer()
	
	Object.Warehouse = SettingsValueCached.GetDefaultWarehouse(Object.Warehouse);
	
EndProcedure

&AtServer
Function GoBack(WaitForAnswerToQuestion)
	ThereAreWriteOffs      = Object.Goods.FindRows(New Structure("TransactionConsumption", True)).Count() > 0;
	ThereArePostings = Object.Goods.FindRows(New Structure("GoodsReceiptTransaction", True)).Count() > 0;
	ThereIsCorruption         = Object.Goods.FindRows(New Structure("OperationDamage", True)).Count() > 0;
	ThereIsResortment   = Object.Goods.FindRows(New Structure("MisgradingOperation", True)).Count() > 0;

	YouNeedToOpenCredits = (ThereAreWriteOffs And ThereArePostings)
							Or ThereIsCorruption
							Or ThereIsResortment;
	
	CurrentPage = Items.MainPanel.CurrentPage;
	
	If CurrentPage = Items.DocumentProcessingPage Then
		If WarehouseActs.Count() > 0
			And WaitForAnswerToQuestion Then
			Return False;
		Else
			DeleteWarehouseReportsInventoryInventoriesServer();
			If GetFunctionalOption("UseMultipleCompanies") Then
				Items.MainPanel.CurrentPage = Items.OrganizationDistributionPage;
			ElsIf YouNeedToOpenCredits Then 
				Items.MainPanel.CurrentPage = Items.PageReSortingDamage;
			Else
				Items.MainPanel.CurrentPage = Items.SettingsPage;
			EndIf;
		EndIf;
	ElsIf CurrentPage = Items.OrganizationDistributionPage Then
			
			If YouNeedToOpenCredits Then 
				Items.MainPanel.CurrentPage = Items.PageReSortingDamage;
			Else
				If WaitForAnswerToQuestion Then
					Return False;
				Else
					Items.MainPanel.CurrentPage = Items.SettingsPage;
				EndIf;
			EndIf; 
	ElsIf CurrentPage = Items.PageReSortingDamage Then
		
		If (ThereIsCorruption
			Or ThereIsResortment)
			And WaitForAnswerToQuestion Then
			Return False;
		Else
			Items.MainPanel.CurrentPage = Items.SettingsPage;
		EndIf;
		
	EndIf;	
			
			
	If Items.MainPanel.CurrentPage = Items.SettingsPage Then
		SetDisplayByWarehouse();
	EndIf;
	
	SetDisplayOfTitleAndControls();
	
	Return True;
EndFunction

&AtServerNoContext
Function ThereAreUnformulatedWarehouseRecalculationsServer(Val Warehouse)
	
	Return Documents.InventoryRecount.UnformattedRecalculationsByWarehouse(Warehouse).Count() > 0;
	
EndFunction

&AtServerNoContext
Function GetCompletedAndUnprovenWarehouseReports(Val CertificateList, ReturnedArrayOfUnverifiedActs, ReturnedArrayOfCompletedActs)
	
	Query = New Query;
	Query.SetParameter("CertificateList",CertificateList);
	Query.Text =
	"SELECT
	|	InventorySurplusRecognition.Ref
	|FROM
	|	Document.InventorySurplusRecognition AS InventorySurplusRecognition
	|WHERE
	|	NOT InventorySurplusRecognition.Posted
	|	AND InventorySurplusRecognition.Ref IN(&CertificateList)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsMisgrading.Ref
	|FROM
	|	Document.GoodsMisgrading AS GoodsMisgrading
	|WHERE
	|	NOT GoodsMisgrading.Posted
	|	AND GoodsMisgrading.Ref IN(&CertificateList)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsDamage.Ref
	|FROM
	|	Document.GoodsDamage AS GoodsDamage
	|WHERE
	|	NOT GoodsDamage.Posted
	|	AND GoodsDamage.Ref IN(&CertificateList)
	|
	|UNION ALL
	|
	|SELECT
	|	WriteOffOfGoodsShortages.Ref
	|FROM
	|	Document.WriteOffOfGoodsShortages AS WriteOffOfGoodsShortages
	|WHERE
	|	NOT WriteOffOfGoodsShortages.Posted
	|	AND WriteOffOfGoodsShortages.Ref IN(&CertificateList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventorySurplusRecognition.Ref
	|FROM
	|	Document.InventorySurplusRecognition AS InventorySurplusRecognition
	|WHERE
	|	InventorySurplusRecognition.Posted
	|	AND InventorySurplusRecognition.Ref IN(&CertificateList)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsMisgrading.Ref
	|FROM
	|	Document.GoodsMisgrading AS GoodsMisgrading
	|WHERE
	|	GoodsMisgrading.Posted
	|	AND GoodsMisgrading.Ref IN(&CertificateList)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsDamage.Ref
	|FROM
	|	Document.GoodsDamage AS GoodsDamage
	|WHERE
	|	GoodsDamage.Posted
	|	AND GoodsDamage.Ref IN(&CertificateList)
	|
	|UNION ALL
	|
	|SELECT
	|	WriteOffOfGoodsShortages.Ref
	|FROM
	|	Document.WriteOffOfGoodsShortages AS WriteOffOfGoodsShortages
	|WHERE
	|	WriteOffOfGoodsShortages.Posted
	|	AND WriteOffOfGoodsShortages.Ref IN(&CertificateList)";
	
	Result = Query.ExecuteBatch();
	ReturnedArrayOfUnverifiedActs = Result.Get(0).Unload().UnloadColumn("Ref");
	ReturnedArrayOfCompletedActs = Result.Get(1).Unload().UnloadColumn("Ref");
	
EndFunction

&AtServer
Procedure SetDisplayByWarehouse()
	
	If ValueIsFilled(Object.Warehouse) Then
		
		Items.WarehouseSelectionGroup_3.CurrentPage = Items.WarehouseSelectionGroupSelected;
		
		If CheckBoxThereAreIncompleteRecountsInTheWarehouse Then
			TitleText = NStr("vi = 'Có chứng từ <a href=""Отчет"">kiểm đếm hàng hóa</a>,mà vẫn chưa nhập xong kết quả (chứng từ chưa kết chuyển với trạng thái ""Đã thực hiện"").';
							|ru = 'Есть <a href=""Отчет"">пересчеты товаров</a>, по которым еще не завершено внесение результатов (они не проведены в статусе ""Выполнено"").';
							|en = 'There are <a href=""Отчет"">inventory counts</a> which are not entered yet (they are not posted in the ""Completed"" status).'; fa = 'There are <a href=""Отчет"">inventory counts</a> which are not entered yet (they are not posted in the ""Completed"" status).';
							|it = 'Есть <a href=""Отчет"">пересчеты товаров</a>, по которым еще не завершено внесение результатов (они не проведены в статусе ""Выполнено"").';
							|pl = 'There are <a href=""Отчет"">inventory counts</a> which are not entered yet (they are not posted in the ""Completed"" status).';
							|tr = 'Sonuçları henüz tamamlanmamış (""Tamamlandı"" durumunda kaydedilmemiş) ürünlerin yeniden hesaplamaları mevcut.'");
			
			Items.DecorationInformingAboutUnformedRecalculations.Title = StringFunctions.FormattedString(TitleText);
		Else
			Items.DecorationInformingAboutUnformedRecalculations.Title = NStr("vi = 'Theo kho đã chọn, toàn bộ hàng hóa đã được kiểm đếm.';
																				|ru = 'По выбранному складу все пересчеты товаров выполнены.';
																				|en = 'All inventory is recalculated for the selected warehouse.'; fa = 'All inventory is recalculated for the selected warehouse.';
																				|it = 'Per il magazzino selezionato tutti i ricalcoli delle merci sono eseguiti.';
																				|pl = 'Dla wybranego magazynu wszystkie przeliczenia towarów zostały wykonane.';
																				|tr = 'Seçilen ambar için tüm ürünlerin yeniden hesaplamaları tamamlandı.'");
		EndIf;
		
		If Not (GetFunctionalOption("UseItemVariants")
			Or GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure("Warehouse", Object.Warehouse))) Then
			Items.RowSelectionGroup.Visible = False;
		Else
			Items.RowSelectionGroup.Visible = True;
		EndIf;
		
	Else
		Items.WarehouseSelectionGroup_3.CurrentPage = Items.WarehouseSelectionGroupNotSelected;
	EndIf;
	
	ManageDecorationsByProduct();
	
	SetDisplayOfTitleAndControls();
	
EndProcedure

&AtServer
Procedure GenerateListOfMatchingItemsServer()
	
	If Not Items.WarehouseSelectionGroup_3.Visible Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Goods", Object.Goods.Unload());
	Query.Text =
	"SELECT
	|	Goods.ProductsWrittenOff AS Products
	|INTO TableForDebiting
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.TransactionText = ""WriteOff""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.ProductsRecordedAsReceived AS Products
	|INTO TableForRegistration
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.TransactionText = ""RecordingAsReceived""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableForRegistration.Products AS Products,
	|	CAST(TableForRegistration.Products AS Catalog.Products).Description AS Description
	|FROM
	|	TableForRegistration AS TableForRegistration
	|		INNER JOIN TableForDebiting AS TableForDebiting
	|		ON TableForRegistration.Products = TableForDebiting.Products
	|
	|ORDER BY
	|	Description";
	Selection = Query.Execute().Select();
	
	Items.PickProductsLines.ChoiceList.Clear();
	
	If Selection.Count() = 0 Then
		Items.PagesExplanationFilterLines.CurrentPage = Items.PageExplanationNoFilterLine;
		Items.PickProductsLines.Enabled          = False;
		If ValueIsFilled(PickProductsLines) Then
			PickProductsLines = Catalogs.Products.EmptyRef();
			SetSelectionOfLinesByNomenclatureServer();
		EndIf;
	Else
		Items.PagesExplanationFilterLines.CurrentPage = Items.PageExplanationYesFilterLines;
		Items.PickProductsLines.Enabled          = True;
		While Selection.Next() Do
			Items.PickProductsLines.ChoiceList.Add(Selection.Products, Selection.Description);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettingsServer()
	
	Var Settings;
	
	Settings = Common.CommonSettingsStorageLoad("DataProcessors.WarehouseGoodsIssueReceiptWizard", "");
	SelectedOwnersByWarehouse = Undefined;
	
	If TypeOf(Settings) = Type("Map") Then
		SelectedOwnersByWarehouse = Settings.Get("SelectedOrganizationsByWarehouse");
	EndIf;
	
	If TypeOf(SelectedOwnersByWarehouse) = Type("ValueTable") Then
		RowFilter  = New Structure("Warehouse", Object.Warehouse);
		RowsArray = SelectedOwnersByWarehouse.FindRows(RowFilter);
		
		For Each String In RowsArray Do
			SelectedOwnersByWarehouse.Delete(String);
		EndDo;
	Else
		SelectedOwnersByWarehouse = New ValueTable();
		SelectedOwnersByWarehouse.Columns.Add("Warehouse",       New TypeDescription("CatalogRef.Warehouses"));
		SelectedOwnersByWarehouse.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
		SelectedOwnersByWarehouse.Columns.Add("Priority",   TMCommonUse.GetDescriptionOfNumberTypes(15, 0));
	EndIf;
	
	For Each SelectedOrganization In Object.SelectedCompanies Do
		String = SelectedOwnersByWarehouse.Add();
		FillPropertyValues(String, SelectedOrganization);
		
		String.Warehouse     = Object.Warehouse;
		String.Priority = SelectedOrganization.LineNumber;
	EndDo;
	
	Settings = New Map;
	Settings.Insert("SelectedOrganizationsByWarehouse", SelectedOwnersByWarehouse);
	
	Common.CommonSettingsStorageSave("DataProcessors.WarehouseGoodsIssueReceiptWizard", "", Settings);
	
EndProcedure

&AtServer
Procedure LoadSettingsServer()
	
	Settings = Common.CommonSettingsStorageLoad("DataProcessors.WarehouseGoodsIssueReceiptWizard", "");
	
	If TypeOf(Settings) = Type("Map") Then
		SelectedOrganizationsByWarehouse = Settings.Get("SelectedOrganizationsByWarehouse");
		
		If TypeOf(SelectedOrganizationsByWarehouse) = Type("ValueTable") Then
			RowFilter  = New Structure("Warehouse", Object.Warehouse);
			RowsArray = SelectedOrganizationsByWarehouse.FindRows(RowFilter);
			
			If RowsArray.Count() > 0 Then
				Table = SelectedOrganizationsByWarehouse.Copy(RowsArray);
				Table.Sort("Priority");
				
				Object.SelectedCompanies.Clear();
				
				For Each TableRow In Table Do
					NewRow = Object.SelectedCompanies.Add();
					FillPropertyValues(NewRow, TableRow);
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function GetNumberOfProductsToBeProcessed(Val WithoutSelectingProducts)
	Return DataProcessors.WarehouseGoodsIssueReceiptWizard.GoodsForRegistrationOfWarehouseActs(Object.Warehouse, 
				?(WithoutSelectingProducts, Undefined, FilterOfProductItem), StocktakingPeriod.StartDate, StocktakingPeriod.EndDate).Count();
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	//
	
	#Region ConditionalAppearanceOfCharacteristic
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToWriteOffItemVariantOfGoodsIssue.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemVariantOfGoodsIssue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.ItemsCharacteristics.EmptyRef();

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToRecordAsReceivedItemVariantOfGoodsReceipt.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemVariantOfGoodsReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.ItemsCharacteristics.EmptyRef();

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToBeReSortedToBeDamagedCharacteristicsDebited.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemVariantOfGoodsIssue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.ItemsCharacteristics.EmptyRef();

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToBeReSortedToBeDamagedCharacteristicsToBeReceived.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemVariantOfGoodsReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.ItemsCharacteristics.EmptyRef();

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	//
	
	#Region ConditionalAppearanceOfSeries
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToWriteOffWrittenOffBatch.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.WrittenOffBatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.ItemsBatches.EmptyRef();

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra sê-ri>';
													|ru = '<серия не указывается>';
													|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
													|it = '<serie non è indicata>';
													|pl = '<seria nie jest określana>';
													|tr = '<parti belirtilmemektedir>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToRecordAsReceivedRecordedAsReceivedBatch.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RecordedAsReceivedBatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.ItemsBatches.EmptyRef();

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra sê-ri>';
													|ru = '<серия не указывается>';
													|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
													|it = '<serie non è indicata>';
													|pl = '<seria nie jest określana>';
													|tr = '<parti belirtilmemektedir>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToBeReSortedToBeDamagedSeriesDebited.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.WrittenOffBatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.ItemsBatches.EmptyRef();

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra sê-ri>';
													|ru = '<серия не указывается>';
													|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
													|it = '<serie non è indicata>';
													|pl = '<seria nie jest określana>';
													|tr = '<parti belirtilmemektedir>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsToBeReSortedToBeDamagedSeriesReceived.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RecordedAsReceivedBatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.ItemsBatches.EmptyRef();

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra sê-ri>';
													|ru = '<серия не указывается>';
													|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
													|it = '<serie non è indicata>';
													|pl = '<seria nie jest określana>';
													|tr = '<parti belirtilmemektedir>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	// Setting the conditional design for the 'OperatioNtext' field of the tabular parts of the form.
	DataProcessors.WarehouseGoodsIssueReceiptWizard.SetConditionalFormattingOperationText(ThisForm,
																						"GoodsForMisgradingForDamageTransactionText");
	DataProcessors.WarehouseGoodsIssueReceiptWizard.SetConditionalFormattingOperationText(ThisForm,
																						"ProductsNotDistributedTransactionText");
	DataProcessors.WarehouseGoodsIssueReceiptWizard.SetConditionalFormattingOperationText(ThisForm,
																						"AllocatedGoodsTransactionText",
																						"Object.AllocatedGoods.TransactionText");
	
EndProcedure

&AtServer
Procedure SetNewKindOfPriceServer(Val SourseOfInformationAboutPricesForPrinting)
	
	If SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByPriceType Then
		Items.PriceKind.Enabled = True;
	ElsIf SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost Then
		Items.PriceKind.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPriceViewValueServer(Val SourseOfInformationAboutPricesForPrinting)
	
	If SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByPriceType Then
		Object.PriceKind = Catalogs.Warehouses.AccountingPriceType(Object.Warehouse);
	ElsIf SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost Then
		Object.PriceKind = Undefined;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function PlaceProductSelectionSettingsToTemporaryStorageServer(Val FilterOfProductItem)
	SelectionOfProductsSetting = FilterOfProductItem.GetSettings();
	Return PutToTempStorage(SelectionOfProductsSetting);
EndFunction

&AtServer
Function PrepareTableOfProductsForServerReport()
	
	Query = New Query;
	Query.SetParameter("TableOfGoods", Object.Goods.Unload());
	TransactionTypes = SelectByOperationType.UnloadValues();
	Query.SetParameter("TransactionTypes", TransactionTypes);
	Query.SetParameter("OperationTypesSelected", ValueIsFilled(TransactionTypes));
	Query.Text = 
	"SELECT
	|	TableOfGoods.ProductsWrittenOff,
	|	TableOfGoods.ItemVariantOfGoodsIssue,
	|	TableOfGoods.AssignmentOfWrittingOff,
	|	TableOfGoods.WrittenOffBatch,
	|	TableOfGoods.ProductsRecordedAsReceived,
	|	TableOfGoods.ItemVariantOfGoodsReceipt,
	|	TableOfGoods.AssignmentRecordedAsReceived,
	|	TableOfGoods.RecordedAsReceivedBatch,
	|	TableOfGoods.QuantityNotAllocated
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.QuantityNotAllocated <> 0
	|	AND (NOT &OperationTypesSelected
	|			OR TableOfGoods.TransactionText IN (&TransactionTypes))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.ProductsWrittenOff AS Products,
	|	TableOfGoods.ItemVariantOfGoodsIssue AS Characteristic,
	|	TableOfGoods.AssignmentOfWrittingOff AS Purpose,
	|	TableOfGoods.WrittenOffBatch AS Series,
	|	TableOfGoods.QuantityNotAllocated AS Count,
	|	0 AS QuantityToRecordAsReceived,
	|	TableOfGoods.QuantityNotAllocated AS QuantityToWriteOff
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.ProductsWrittenOff <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.ProductsRecordedAsReceived,
	|	TableOfGoods.ItemVariantOfGoodsReceipt,
	|	TableOfGoods.AssignmentRecordedAsReceived,
	|	TableOfGoods.RecordedAsReceivedBatch,
	|	TableOfGoods.QuantityNotAllocated,
	|	TableOfGoods.QuantityNotAllocated,
	|	0
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.ProductsRecordedAsReceived <> VALUE(Catalog.Products.EmptyRef)";
	Table = Query.Execute().Unload();
	
	Return ValueToStringInternal(Table);
	
EndFunction

&AtServer
Function SetOffByReSortingTheCarServer()
	
	Result = 0;
			
	// by re - sorting
	VariantsTable = GetOptionsForOffsettingByResortmentServer();
	OffsetGoodsByOperation(VariantsTable, "Misgrading", Result);
	
	If Result > 0 Then
		GenerateListOfMatchingItemsServer();
	EndIf;
	
	SortTableByOperationProductDescription(Object.Goods);
	
	Return Result;
	
EndFunction

&AtServer
Function CreditForDamageToTheCarServer()
	
	Result = 0;
	
	// by spoiling
	VariantsTable = GetOptionsForScoringServerDamage();
	OffsetGoodsByOperation(VariantsTable, "Damage", Result);
			
	SortTableByOperationProductDescription(Object.Goods);
	
	Return Result;
	
EndFunction

&AtServer
Procedure OffsetGoodsByOperation(VariantsTable, Operation, Result)
	
	TableOfGoods = VariantsTable.Copy(, "ProductsWrittenOff, ItemVariantOfGoodsIssue, AssignmentOfWrittingOff, WrittenOffBatch");
	TableOfGoods.GroupBy("ProductsWrittenOff, ItemVariantOfGoodsIssue, AssignmentOfWrittingOff, WrittenOffBatch");
	For Each OwnGoods In TableOfGoods Do
		
		Filter = New Structure;
		Filter.Insert("ProductsWrittenOff", OwnGoods.ProductsWrittenOff);
		Filter.Insert("ItemVariantOfGoodsIssue", OwnGoods.ItemVariantOfGoodsIssue);
		Filter.Insert("AssignmentOfWrittingOff", OwnGoods.AssignmentOfWrittingOff);
		Filter.Insert("WrittenOffBatch", OwnGoods.WrittenOffBatch);
		
		ArrayOfVariantStrings = VariantsTable.FindRows(Filter);
		
		Filter.Insert("TransactionText", "WriteOff");
		
		ArrayOfRowsProductsDebited = Object.Goods.FindRows(Filter);
		
		If ArrayOfRowsProductsDebited.Count() = 0 Then
			Continue;
		EndIf;
		
		ProductsDebitedLine = ArrayOfRowsProductsDebited[0];
		For Each Variant In ArrayOfVariantStrings Do
			
			Filter = New Structure;
			Filter.Insert("TransactionText", "RecordingAsReceived");
			Filter.Insert("ProductsRecordedAsReceived", Variant.ProductsRecordedAsReceived);
			Filter.Insert("ItemVariantOfGoodsReceipt", Variant.ItemVariantOfGoodsReceipt);
			Filter.Insert("AssignmentRecordedAsReceived", Variant.AssignmentRecordedAsReceived);
			Filter.Insert("RecordedAsReceivedBatch", Variant.RecordedAsReceivedBatch);
			
			ArrayOfRowsProductsComingIn = Object.Goods.FindRows(Filter);
			
			If ArrayOfRowsProductsComingIn.Count() = 0 Then
				Continue;
			EndIf;
			
			IncomingGoodsLine_ = ArrayOfRowsProductsComingIn[0];
			Count = Min(ProductsDebitedLine.QuantityNotAllocated, IncomingGoodsLine_.QuantityNotAllocated);
			
			CreateNewRowByOffsetServer(ProductsDebitedLine, IncomingGoodsLine_, Operation, Count);
			Result = Result + 1;
			
			If IncomingGoodsLine_.Count = 0 Then
				Object.Goods.Delete(IncomingGoodsLine_);
			EndIf;
			If ProductsDebitedLine.Count = 0 Then
				Break;
			EndIf;
		EndDo;
		If ProductsDebitedLine.Count = 0 Then
			Object.Goods.Delete(ProductsDebitedLine);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure DistributeForCompanyCompletionServer(Val Result,Val IdsOfSelectedRows)
	
	Organization = Result;
	
	For Each IDOfSelectedRow_ In IdsOfSelectedRows Do
		
		String = Object.Goods.FindByID(IDOfSelectedRow_);
		
		DistributeOperationToOrganizationServer(String, Organization);
		
	EndDo;
	
	ProductsNotDistributedUpdateFilter();
	SortTableOfDistributedGoods(Object.AllocatedGoods);
	
EndProcedure

&AtServer
Function DistributeByOrganizationCompletionServer(Val Result, Val AdditionalParameters)
	
	CreatedRows = 0;
	
	If Object.Goods.Count() = 0
		Or Object.Goods.Total("QuantityNotAllocated") = 0 Then
		
		Return CreatedRows;
		
	EndIf;
	
	Object.SelectedCompanies.Clear();
	
	For Each Organization In Result Do
		String = Object.SelectedCompanies.Add();
		String.Organization = Organization;
	EndDo;
	
	DistributionTable_ = DataToDistribution();
	
	For Each StringDistribution In DistributionTable_ Do
		Filter = New Structure("TransactionText, ProductsWrittenOff, ProductsRecordedAsReceived, ItemVariantOfGoodsIssue,
					|ItemVariantOfGoodsReceipt, AssignmentOfWrittingOff, AssignmentRecordedAsReceived, WrittenOffBatch, RecordedAsReceivedBatch");
		FillPropertyValues(Filter, StringDistribution);
		RowsArray = Object.Goods.FindRows(Filter);
		
		DistributeOperationToOrganizationServer(RowsArray[0], StringDistribution.Organization, StringDistribution);
		
		CreatedRows = CreatedRows + 1;
	EndDo;
	
	ProductsNotDistributedUpdateFilter();
	SortTableOfDistributedGoods(Object.AllocatedGoods);
	
	Return CreatedRows;
	
EndFunction

&AtServer
Procedure SetOffByReSortingByDamageCompletionServer(Val Var_Parameters, Val EnteredNumber)
	
	ProductsDebitedLine = Object.Goods.FindByID(Var_Parameters.CurWriteOffData);
	IncomingGoodsLine_ = Object.Goods.FindByID(Var_Parameters.CurRegistrationData);
	
	ThisIsCorruption = 
		InformationRegisters.AnotherQualityGoods.CheckForGradation(
				ProductsDebitedLine.ProductsWrittenOff,
				IncomingGoodsLine_.ProductsRecordedAsReceived)
			And String(ProductsDebitedLine.ItemVariantOfGoodsIssue) = String(IncomingGoodsLine_.ItemVariantOfGoodsReceipt)
			And String(ProductsDebitedLine.WrittenOffBatch) = String(IncomingGoodsLine_.RecordedAsReceivedBatch);
	
	TransactionText = ?(ThisIsCorruption, "Damage", "Misgrading");
	
	CreateNewRowByOffsetServer(ProductsDebitedLine, IncomingGoodsLine_, TransactionText, EnteredNumber);
	
	FilterWriteOffs = New Structure("TransactionConsumption", True);
	ParishSelection_ = New Structure("GoodsReceiptTransaction", True);
	
	ItemsToBeDebited = Object.Goods.FindRows(FilterWriteOffs);
	RecordedAsReceivedGoods = Object.Goods.FindRows(ParishSelection_);
	
	IndexOfProductBeingWrittenOff = ItemsToBeDebited.Find(ProductsDebitedLine);
	IndexOfIncomingGoods = RecordedAsReceivedGoods.Find(IncomingGoodsLine_);
		
	If IncomingGoodsLine_.Count = 0 Then
		Object.Goods.Delete(IncomingGoodsLine_);
		
		If (RecordedAsReceivedGoods.Count() - 1) > IndexOfIncomingGoods Then
			CurLineOfName = RecordedAsReceivedGoods.Get(IndexOfIncomingGoods + 1);
			IDOfNameLine = CurLineOfName.GetID();
		ElsIf (RecordedAsReceivedGoods.Count() - 1) > 0 Then
			CurLineOfName = RecordedAsReceivedGoods.Get(IndexOfIncomingGoods - 1);
			IDOfNameLine = CurLineOfName.GetID();
		EndIf;
		
		Items.GoodsToRecordAsReceived.CurrentRow = IDOfNameLine;
	EndIf;
	
	If ProductsDebitedLine.Count = 0 Then
		Object.Goods.Delete(ProductsDebitedLine);
		
		If (ItemsToBeDebited.Count() - 1) > IndexOfProductBeingWrittenOff Then
			CurChargeLine = ItemsToBeDebited.Get(IndexOfProductBeingWrittenOff + 1);
			IDOfChargeLine = CurChargeLine.GetID();
		ElsIf (ItemsToBeDebited.Count() - 1) > 0 Then
			CurChargeLine = ItemsToBeDebited.Get(IndexOfProductBeingWrittenOff - 1);
			IDOfChargeLine = CurChargeLine.GetID();
		EndIf;
		
		Items.GoodsToWriteOff.CurrentRow = IDOfChargeLine;
	EndIf;
	
	GenerateListOfMatchingItemsServer();
	
	SortTableByOperationProductDescription(Object.Goods);
	
EndProcedure

&AtServer
Procedure SwitchingToOffsetStep()
	
	PrepareProductTableForOperation();
	
	If Object.Goods.FindRows(New Structure("TransactionConsumption", True)) = 0
		Or Object.Goods.FindRows(New Structure("TransactionConsumption", True)) = 0 Then
		SwitchingToDistributionByOrganizationsStep()
	Else
		Items.MainPanel.CurrentPage = Items.PageReSortingDamage;
		SetDisplayOfTitleAndControls();
	EndIf;
	
EndProcedure

&AtServer
Procedure SwitchingToDistributionByOrganizationsStep()
	If ValueIsFilled(SoleCompany) Then
		RowsArray = New Array;
		For Each String In Object.Goods Do
			RowsArray.Add(String.GetID());
		EndDo;
		
		DistributeForCompanyCompletionServer(SoleCompany, RowsArray);
		GoToRegistrationOfActsStep();
	Else
		Items.MainPanel.CurrentPage = Items.OrganizationDistributionPage;	
		SetDisplayOfTitleAndControls();
	EndIf;
EndProcedure

&AtServer
Procedure GoToRegistrationOfActsStep()
	RegisterWarehouseActsServer();
	Items.MainPanel.CurrentPage = Items.DocumentProcessingPage;
	SetDisplayOfTitleAndControls();
EndProcedure

&AtServer
Procedure GoodsForMisgradingForDamageBeforeDeleteRowServer(Val IdsOfSelectedRows)
	
	For Each RowID In IdsOfSelectedRows Do
		StringSpoilageReSorting = Object.Goods.FindByID(RowID);
		
		Filter = New Structure;
		Filter.Insert("TransactionText",		"WriteOff");
		Filter.Insert("TransactionConsumption",	True);
		Filter.Insert("ProductsWrittenOff",	StringSpoilageReSorting.ProductsWrittenOff);
		Filter.Insert("ItemVariantOfGoodsIssue", StringSpoilageReSorting.ItemVariantOfGoodsIssue);
		Filter.Insert("AssignmentOfWrittingOff",		StringSpoilageReSorting.AssignmentOfWrittingOff);
		Filter.Insert("WrittenOffBatch",			StringSpoilageReSorting.WrittenOffBatch);
		Filter.Insert("PriceOfGoodsIssue",				StringSpoilageReSorting.PriceOfGoodsIssue);
		Filter.Insert("VATRate",					StringSpoilageReSorting.VATRate);
		RowsArray = Object.Goods.FindRows(Filter);
		If RowsArray.Count() = 0 Then
			String = Object.Goods.Add();
			FillPropertyValues(String, Filter);
		Else
			String = RowsArray[0];
		EndIf;
		String.Count = String.Count + StringSpoilageReSorting.Count;
		String.QuantityNotAllocated = String.QuantityNotAllocated + StringSpoilageReSorting.Count;
		String.NotAllocated = Not String.QuantityNotAllocated = 0;
		String.Allocated = Not String.QuantityIsAllocated = 0;
		String.FilterFlag = Not SelectByOperationType.FindByValue(String.TransactionText) = Undefined;
		
		Filter = New Structure;
		Filter.Insert("TransactionText",			"RecordingAsReceived");
		Filter.Insert("GoodsReceiptTransaction", True);
		Filter.Insert("ProductsRecordedAsReceived", 	StringSpoilageReSorting.ProductsRecordedAsReceived);
		Filter.Insert("ItemVariantOfGoodsReceipt", StringSpoilageReSorting.ItemVariantOfGoodsReceipt);
		Filter.Insert("AssignmentRecordedAsReceived", 	StringSpoilageReSorting.AssignmentRecordedAsReceived);
		Filter.Insert("RecordedAsReceivedBatch",			StringSpoilageReSorting.RecordedAsReceivedBatch);
		Filter.Insert("PriceOfPurchaseInvoice",			StringSpoilageReSorting.PriceOfPurchaseInvoice);
		Filter.Insert("VATRate",					StringSpoilageReSorting.VATRate);
		RowsArray = Object.Goods.FindRows(Filter);
		If RowsArray.Count() = 0 Then
			String = Object.Goods.Add();
			FillPropertyValues(String, Filter);
		Else
			String = RowsArray[0];
		EndIf;
		String.Count = String.Count + StringSpoilageReSorting.Count;
		String.QuantityNotAllocated = String.QuantityNotAllocated + StringSpoilageReSorting.Count;
		String.NotAllocated = Not String.QuantityNotAllocated = 0;
		String.Allocated = Not String.QuantityIsAllocated = 0;
		String.FilterFlag = Not SelectByOperationType.FindByValue(String.TransactionText) = Undefined;

		RowsArray = Object.AllocatedGoods.FindRows(
			New Structure("ConnectionKey", StringSpoilageReSorting.GetID()));
			
		For Each String In RowsArray Do
			Object.AllocatedGoods.Delete(String);
		EndDo;
		
		Object.Goods.Delete(StringSpoilageReSorting);
	EndDo;
	
	GenerateListOfMatchingItemsServer();
	
	SortTableByOperationProductDescription(Object.Goods);
	
EndProcedure

&AtServer
Procedure DetermineDateOfRegistrationOfWarehouseActs()
	
	CurrentDate = CurrentSessionDate();
	If (CurrentDate < StocktakingPeriod.StartDate 
			Or CurrentDate > StocktakingPeriod.EndDate) Then
			
		WarehouseActDate = StocktakingPeriod.EndDate;
	Else
		WarehouseActDate = CurrentDate;
	EndIf;
	
EndProcedure

&AtServer
Procedure GoToNewServerSelections()
	
	WarehouseOnChangeServer();
	
	Items.MainPanel.CurrentPage = Items.SettingsPage;
	SetDisplayOfTitleAndControls();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SortTableByOperationProductDescription(Table)

	Table.Sort("TransactionText Asc, ProductsWrittenOff Asc, ItemVariantOfGoodsIssue Asc, ProductsRecordedAsReceived Asc, ItemVariantOfGoodsReceipt Asc");
	
EndProcedure

&AtClientAtServerNoContext
Procedure SortTableOfDistributedGoods(Table)
	
	Table.Sort("TransactionText, Organization,  ProductsWrittenOff, ItemVariantOfGoodsIssue,
				|ProductsRecordedAsReceived, ItemVariantOfGoodsReceipt");
	
EndProcedure

&AtServer
Function FillingDataStructure(Organization, DocumentDate)
	
	FillingData = New Structure;
	
	FillingData.Insert("Date", DocumentDate);
	FillingData.Insert("Organization", Organization);
	FillingData.Insert("Warehouse", Object.Warehouse);
	FillingData.Insert("SourseOfInformationAboutPricesForPrinting", Object.SourseOfInformationAboutPricesForPrinting);
	FillingData.Insert("PriceKind", Object.PriceKind);
	FillingData.Insert("EmployeeResponsible", Users.CurrentUser());
	FillingData.Insert("DoNotFillInWrongPart");
	
	Return FillingData;
	
EndFunction

&AtClient
Procedure TSSelectionEventForItemsToBeDebited(Field, Item)
	
	If StrFind(Upper(Field.Name), "RECEIPT") > 0 Then // incoming goods
		ShowValue(,Item.CurrentData.ProductsRecordedAsReceived);
	ElsIf StrFind(Upper(Field.Name), "SPIS") > 0 Then // items being written off
		ShowValue(,Item.CurrentData.ProductsWrittenOff);
	EndIf;
	
EndProcedure

// Parameters:
// 	RecordKey - FormDataStructure - Where:
// 		* Ref - DocumentRef
// Returns:
// 		DocumentRef
&AtServerNoContext
Function DocumentReferenceByRecordKey(RecordKey)
	
	Return RecordKey.Ref;
	
EndFunction 

&AtServer
Procedure SetTitleOfProductSelectionScenery()
	
	Var RowsArray, FilterPresentation;
	
	RowsArray = New Array;
	RowsArray.Add(NStr("vi = 'Lọc mặt hàng:';
						|ru = 'Отбор номенклатуры:';
						|en = 'Filter product:'; fa = 'Filter product:';
						|it = 'Selezione articoli:';
						|pl = 'Filtr wierszy pozycji:';
						|tr = 'Ürün gamı filtresi:'") + " ");
	FilterPresentation = String(FilterOfProductItem.Settings.Filter);
	If ValueIsFilled(FilterPresentation) Then
		RowsArray.Add(FilterPresentation + ". ");
	Else
		RowsArray.Add(NStr("vi = '<chưa thiết lập>.';
							|ru = '<не установлен>.';
							|en = '<not set>.'; fa = '<not set>.';
							|it = '<non impostato>.';
							|pl = '<nie ustawiono>.';
							|tr = '<ayarlanmadı>.'") + " ");
	EndIf;
	RowsArray.Add(New FormattedString(NStr("vi = 'Đặt bộ lọc';
											|ru = 'Установить отбор';
											|en = 'Set filter'; fa = 'تعیین فیلتر';
											|it = 'Impostare selezione';
											|pl = 'Ustaw wybór';
											|tr = 'Filtre kur'"),,,,"Filter"));
	Items.DecorationItemSelection.Title = New FormattedString(RowsArray);
	
EndProcedure

&AtServer
Procedure CustomizeFormLocalization()
	
	Return;
	
EndProcedure

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
