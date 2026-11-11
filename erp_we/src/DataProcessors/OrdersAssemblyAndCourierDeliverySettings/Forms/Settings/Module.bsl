
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Parameters.Property("StoreSupportsOrderAssembly", StoreSupportsOrderAssembly);
	Parameters.Property("StoreSupportsDeliveryByOwnCouriers", StoreSupportsDeliveryByOwnCouriers);
	Parameters.Property("MethodOfSalesCreatingWhenAssemblingOrders", MethodOfSalesCreatingWhenAssemblingOrders);
	Parameters.Property("MethodOfFiscalizationUponDelivery", MethodOfFiscalizationUponDelivery);
	Parameters.Property("AssemblyAndDeliveryIsDoneBySameEmployee", AssemblyAndDeliveryIsDoneBySameEmployee);
	Parameters.Property("CouriersCanAssignOrdersToThemselves", CouriersCanAssignOrdersToThemselves);
	Parameters.Property("PickersCanAssignJobsToThemselves", PickersCanAssignJobsToThemselves);
	Parameters.Property("StandardOrderDeliveryTime", StandardOrderDeliveryTime);
	Parameters.Property("CouriersUsePOSTerminals", CouriersUsePOSTerminals);
	Parameters.Property("CouriersUseAutonomousCREs", CouriersUseAutonomousCREs);
	Parameters.Property("OrderAssemblyStartDate", OrderAssemblyStartDate);
	Parameters.Property("StartDateOfDeliveryByOwnCouriers", StartDateOfDeliveryByOwnCouriers);
	Parameters.Property("GroupingOfGoods", GroupingOfGoods);
	Parameters.Property("FormMode", FormMode);
	
	FormObject = Undefined;//CatalogObject
	If Parameters.Property("Object", FormObject) Then
		IsNew = FormObject.Ref.IsEmpty();
		ObjectAttributesLock.LockAttributes(ThisForm, CommandBar, , FormObject);
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	SetAccessibilityVisibility();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If SaveParameters
		And Not Exit Then
	
		ParametersStructure = New Structure();
		ParametersStructure.Insert("StoreSupportsOrderAssembly", StoreSupportsOrderAssembly);
		ParametersStructure.Insert("StoreSupportsDeliveryByOwnCouriers", StoreSupportsDeliveryByOwnCouriers);
		ParametersStructure.Insert("MethodOfSalesCreatingWhenAssemblingOrders", MethodOfSalesCreatingWhenAssemblingOrders);
		ParametersStructure.Insert("MethodOfFiscalizationUponDelivery", MethodOfFiscalizationUponDelivery);
		ParametersStructure.Insert("AssemblyAndDeliveryIsDoneBySameEmployee", AssemblyAndDeliveryIsDoneBySameEmployee);
		ParametersStructure.Insert("CouriersCanAssignOrdersToThemselves", CouriersCanAssignOrdersToThemselves);
		ParametersStructure.Insert("PickersCanAssignJobsToThemselves", PickersCanAssignJobsToThemselves);
		ParametersStructure.Insert("StandardOrderDeliveryTime", StandardOrderDeliveryTime);
		ParametersStructure.Insert("CouriersUsePOSTerminals", CouriersUsePOSTerminals);
		ParametersStructure.Insert("CouriersUseAutonomousCREs", CouriersUseAutonomousCREs);
		ParametersStructure.Insert("OrderAssemblyStartDate", OrderAssemblyStartDate);
		ParametersStructure.Insert("StartDateOfDeliveryByOwnCouriers", StartDateOfDeliveryByOwnCouriers);
		ParametersStructure.Insert("GroupingOfGoods", GroupingOfGoods);

		NotifyChoice(ParametersStructure);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not ForcefullyCloseTheForm
		And (Modified And Not SaveParameters) Then
		
		Cancel = True;
		
		If Exit Then
			WarningText = NStr("vi = 'Cài đặt sẽ bị gián đoạn.';
								|ru = 'Настройка будет прервана.';
								|en = 'Customization will be interrupted.'; fa = 'Customization will be interrupted.';
								|it = 'L''impostazione sarà interrotta.';
								|pl = 'Ustawienie będzie przerwane.';
								|tr = 'Ayar iptal edilecek.'");
			Return;
		EndIf;
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatmayın'"));
		
		AdditionalParameters = New Structure;
		ShowQueryBox(
			New CallbackDescription("ShowQuestionBeforeClosingEnd", ThisObject, AdditionalParameters),
			NStr("vi = 'Thông tin chi tiết đã được thay đổi. Đóng mà không lưu chi tiết?';
				|ru = 'Реквизиты были изменены. Закрыть без сохранения реквизитов?';
				|en = 'Details have been changed. Close without saving details?'; fa = 'Details have been changed. Close without saving details?';
				|it = 'I requisiti sono stati modificati. Chiudere senza salvare?';
				|pl = 'Szczegóły zostały zmienione. Zamknij bez zapisywania szczegółów?';
				|tr = 'Öznitelikler değiştirildi. Öznitelikler kaydedilmeden kapatılsın mı?'"),
			ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowQuestionBeforeClosingEnd(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = "Close" Then
		ForcefullyCloseTheForm = True;
		Close(Undefined);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StoreSupportsOrderAssemblyOnChange(Item)
	
	Items.GroupTheBuildSettingsInTheMain.Enabled = StoreSupportsOrderAssembly;
	Items.OrderAssemblyStartDate.Enabled = StoreSupportsOrderAssembly;
	
	If Not StoreSupportsOrderAssembly Then
		PickersCanAssignJobsToThemselves = False;
		AssemblyAndDeliveryIsDoneBySameEmployee = False;
		CreateAnImplementationAutomaticallyAfterTheBuild = False;
		OrderAssemblyStartDate = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure StoreSupportsDeliveryByOwnCouriersOnChange(Item)
	
	Items.GroupShippingPreferencesTheMain.Enabled = StoreSupportsDeliveryByOwnCouriers;
	Items.StartDateOfDeliveryByOwnCouriers.Enabled = StoreSupportsDeliveryByOwnCouriers;
	
	If Not StoreSupportsDeliveryByOwnCouriers Then
		CouriersCanAssignOrdersToThemselves = False;
		CouriersUseAutonomousCREs = False;
		CouriersUsePOSTerminals = False;
		StandardOrderDeliveryTime = 0;
		StartDateOfDeliveryByOwnCouriers = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateAnImplementationAutomaticallyAfterTheBuildOnChange(Item)
	
	MethodOfSalesCreatingWhenAssemblingOrders = MethodOfSalesCreatingWhenAssemblingOrders(CreateAnImplementationAutomaticallyAfterTheBuild);
	
EndProcedure

&AtClient
Procedure StandardDeliveryTimeForOrdersInHoursOnChange(Item)
	
	StandardOrderDeliveryTime = StandardDeliveryTimeForOrdersInHours*60;
	
EndProcedure

&AtClient
Procedure MethodOfFiscalizationOnDeliveryWhenChanging(Item)

	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not IsNew Then
		
		FormParameters = New Structure();
		FormParameters.Insert("FormMode", FormMode);
		
		OpenForm("DataProcessor.OrdersAssemblyAndCourierDeliverySettings.Form.AttributeUnlocking",FormParameters,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        
        ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
        
    EndIf;

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	SaveParameters = True;
	Close();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	SaveParameters = False;
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetAccessibilityVisibility()
	
	Title = ?(FormMode = 2,
				NStr("vi = 'Cài đặt cửa hàng';
					|ru = 'Настройки магазина';
					|en = 'Store settings'; fa = 'Store settings';
					|it = 'Impostazioni punto vendita';
					|pl = 'Ustawienia sklepu';
					|tr = 'Mağaza ayarları'"),
				NStr("vi = 'Tùy chỉnh khuôn dạng cửa hàng';
					|ru = 'Настройки формата магазина';
					|en = 'Store format settings'; fa = 'Store format settings';
					|it = 'Impostazioni formato punto vendita';
					|pl = 'Ustawienia formatu sklepu';
					|tr = 'Mağaza biçim ayarları'"));
	
	UseDeliveryManagement = GetFunctionalOption("UseDeliveryManagement");
	
	CreateAnImplementationAutomaticallyAfterTheBuild = (MethodOfSalesCreatingWhenAssemblingOrders 
		= Enums.MethodsOfSalesCreatingWhenAssemblingOrders.AutomaticallyAfterAssembly);
		
	StandardDeliveryTimeForOrdersInHours = StandardOrderDeliveryTime/60;
	
	If Not ValueIsFilled(MethodOfFiscalizationUponDelivery) Then
		MethodOfFiscalizationUponDelivery = Enums.MethodsOfFiscalizationUponDelivery.UponCreatingOfCustomerInvoice;
	EndIf;
	
	Items.DeliveryGroup.Visible = UseDeliveryManagement;
		
	Items.GroupTheBuildSettingsInTheMain.Enabled = StoreSupportsOrderAssembly;
	Items.OrderAssemblyStartDate.Enabled = StoreSupportsOrderAssembly;
	Items.GroupShippingPreferencesTheMain.Enabled = StoreSupportsDeliveryByOwnCouriers;
	Items.StartDateOfDeliveryByOwnCouriers.Enabled = StoreSupportsDeliveryByOwnCouriers;
	
	Items.OrderAssemblyStartDate.Visible = (FormMode = 2);
	Items.StartDateOfDeliveryByOwnCouriers.Visible = (FormMode = 2);
	
	Items.GroupingOfGoods.ChoiceList.Add("Parent", NStr("vi = 'Nhóm danh sách';
														|ru = 'Группа списка';
														|en = 'List group'; fa = 'گروه فهرست';
														|it = 'Gruppo dell''elenco';
														|pl = 'Grupa listy';
														|tr = 'Liste grubu'"));
	Items.GroupingOfGoods.ChoiceList.Add("ProductKind", NStr("vi = 'Dạng mặt hàng';
															|ru = 'Вид номенклатуры';
															|en = 'Item kind'; fa = 'نوع قلم';
															|it = 'Tipo di articolo';
															|pl = 'Rodzaj pozycji';
															|tr = 'Ürün türü'"));
	Items.GroupingOfGoods.ChoiceList.Add("AccessGroup", NStr("vi = 'Nhóm truy cập';
															|ru = 'Группа доступа';
															|en = 'Access group'; fa = 'گروه دسترسی';
															|it = 'Gruppo d''accesso';
															|pl = 'Grupa dostępu';
															|tr = 'Erişim grubu'"));
	Items.GroupingOfGoods.ChoiceList.Add("Brand", NStr("vi = 'Nhãn hiệu (thương hiệu)';
														|ru = 'Марка (бренд)';
														|en = 'Brand'; fa = 'برند';
														|it = 'Marchio';
														|pl = 'Marka (brand)';
														|tr = 'Marka (marka)'"));
	Items.GroupingOfGoods.ChoiceList.Add("Manufacturer", NStr("vi = 'Nhà sản xuất';
																|ru = 'Производитель';
																|en = 'Manufacturer'; fa = 'تولیدکننده';
																|it = 'Produttore';
																|pl = 'Manufacturer';
																|tr = 'Üretici'"));
	Items.GroupingOfGoods.ChoiceList.Add("FinancialAccountingGroup", NStr("vi = 'Nhóm tùy chỉnh kế toán tài chính';
																			|ru = 'Группа настроек фин. учета';
																			|en = 'Financial accounting settings group'; fa = 'گروه تنظیمات حسابداری مالی';
																			|it = 'Il gruppo delle impostazioni della rilevazione contabile';
																			|pl = 'Grupa ustawień ewidencji finansowej';
																			|tr = 'Finansal muhasebe ayarları grubu'"));
	Items.GroupingOfGoods.ChoiceList.Add("WarehouseGroup", NStr("vi = 'Nhóm kho';
																|ru = 'Складская группа';
																|en = 'Warehouse group'; fa = 'گروه انبار';
																|it = 'Gruppo di magazzini';
																|pl = 'Grupa magazynowa';
																|tr = 'Ambar grubu'"));
	Items.GroupingOfGoods.ChoiceList.Add("ProductCategory", NStr("vi = 'Thể loại hàng hóa';
																|ru = 'Товарная категория';
																|en = 'Product category'; fa = 'دسته محصول';
																|it = 'Categoria merceologica';
																|pl = 'Kategoria produktu';
																|tr = 'Ürün kategorisi'"));
	Items.GroupingOfGoods.ChoiceList.Add("ItemsCollection", NStr("vi = 'Bộ sưu tập (thời vụ)';
																|ru = 'Коллекция (сезон)';
																|en = 'Collection (season)'; fa = 'کلکسیون (فصل)';
																|it = 'Collezione (stagione)';
																|pl = 'Kolekcja (sezon)';
																|tr = 'Koleksiyon (sezon)'"));
	Items.GroupingOfGoods.ChoiceList.Add("ItemsGroup", NStr("vi = 'Nhóm thời vụ';
															|ru = 'Сезонная группа';
															|en = 'Seasonal group'; fa = 'گروه فصلی';
															|it = 'Gruppo stagionale';
															|pl = 'Grupa sezonowa';
															|tr = 'Mevsimsel grup'"));
	
EndProcedure

&AtServerNoContext
Function MethodOfSalesCreatingWhenAssemblingOrders(CreateAnImplementationAutomaticallyAfterTheBuild)
	
	Result = ?(CreateAnImplementationAutomaticallyAfterTheBuild,
		Enums.MethodsOfSalesCreatingWhenAssemblingOrders.AutomaticallyAfterAssembly,
		Enums.MethodsOfSalesCreatingWhenAssemblingOrders.ManuallyByOperator);
	
	Return Result;
	
EndFunction

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
