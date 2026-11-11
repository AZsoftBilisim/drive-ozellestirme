// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CurrentSessionDate = CurrentSessionDate();
	
	TonConversionFactor               = GoodsDelivery.TonConversionFactor();
	CubicMeterConversionFactor     = GoodsDelivery.CubicMeterConversionFactor();
	
	Warehouse = Parameters.Warehouse;
	Zone = Parameters.Zone;
	DeliveryKind = Parameters.DeliveryKind;
	TransportationJob = Parameters.TransportationJob; //Used when forming a list of orders
	FilterByAssigneeType = Parameters.FilterByAssigneeType;
	
	UpdateListOfDeliveryOrders();
	
	UnitOfMeasureForWeight = Constants.UnitOfMeasureForWeight.Get();
	UnitOfMeasureForVolume = Constants.UnitOfMeasureForVolume.Get();
	
	SetColumnHeadersWeightVolumeServer();
	
	Items.DeliveryReferencesWarehouse.Visible = Common.ObjectAttributeValue(Warehouse,"IsFolder");
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	SetHeadersByDeliveryType();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	OwnerGUID = FormOwner.UUID;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOfOrders_OnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateListOfDeliveryOrders();
	
EndProcedure

&AtClient
Procedure DeliveryZoneOnChange(Item)
	
	UpdateListOfDeliveryOrders();
	
EndProcedure

&AtClient
Procedure DateOfOrders_Tuning(Item, Direction, StandardProcessing)
	
	If Not ValueIsFilled(DateOfOrders_) Then
		DateOfOrders_ = CurrentSessionDate;
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOfOrders_StartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not ValueIsFilled(DateOfOrders_) Then
		DateOfOrders_ = CurrentSessionDate;
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterByAssigneeTypeOnChange(Item)
	UpdateListOfDeliveryOrders();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDeliveryReferences

&AtClient
Procedure DeliveryReferencesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not CheckSelectedDimensions() Then
		Return
	EndIf;
	
	If Field = Items.DeliveryReferencesNumber Then
		ShowValue(,Items.DeliveryReferences.CurrentData.ReferenceOrder);
	Else
		Result = SaveResults();
		NotifyChoice(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If Items.DeliveryReferences.CurrentData = Undefined Then
		Return;
	Else
		If Not AreaGroupOrEmpty
			Or CheckSelectedDimensions() Then
			Result = SaveResults();
			NotifyChoice(Result);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateDeliveryLists(Command)
	
	UpdateListOfDeliveryOrders();
	
EndProcedure

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeliveryReferencesAddress.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeliveryReferences.Zone");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.DeliveryZones.EmptyRef();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeliveryReferences.RowAppearance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 5;
	
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont,,, False, True, False, False, ));
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra vùng giao hàng>';
													|ru = '<зона доставки не указана>';
													|en = '<Delivery zone not specified>'; fa = '<Delivery zone not specified>';
													|it = '<Delivery zone not specified>';
													|pl = '<nie wskazano zony dostawy>';
													|tr = '<teslimat bölgesi belirtilmedi>'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeliveryReferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeliveryReferences.RowAppearance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 5;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.ReportGroup1BackColor);
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont,,, True, False, False, False, ));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DeliveryReferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeliveryReferences.RowAppearance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.CalculatePriceColumnUsingFormulasOfOtherPriceKinds);
	
EndProcedure

#Region Other

&AtServer
Procedure SetColumnHeadersWeightVolumeServer()
	
	TextWeight = NStr("vi = 'Trọng lượng cả bì,';
						|ru = 'Вес брутто,';
						|en = 'Gross weight,'; fa = 'Gross weight,';
						|it = 'Peso lordo,';
						|pl = 'Waga brutto,';
						|tr = 'Ağırlık brüt,'") + " " + UnitOfMeasureForWeight;
	TextVolume = NStr("vi = 'Thể tích,';
						|ru = 'Объем,';
						|en = 'Volume,'; fa = 'Volume,';
						|it = 'Volume,';
						|pl = 'Objętość,';
						|tr = 'Hacim,'") + " " + UnitOfMeasureForVolume;
	Items.DeliveryReferencesWeight.Title = TextWeight;
	Items.DeliveryReferencesVolumeM3.Title = TextVolume;
	
EndProcedure

&AtServer
Procedure UpdateListOfDeliveryOrders()
	
	AreaGroupOrEmpty = (Not ValueIsFilled(Zone) Or Common.ObjectAttributeValue(Zone,"IsFolder"));
	GoodsDelivery.UpdateListOfDeliveryOrders(ThisObject);
	
EndProcedure

&AtClient
Function CheckSelectedDimensions()
	
	If Not AreaGroupOrEmpty Then
		Return True;
	EndIf;
	
	For Each Id In Items.DeliveryReferences.SelectedRows Do // Number
		
		If DeliveryReferences.FindByID(Id).GetParent() = Undefined Then
			
			MessageText = NStr("vi = 'Chọn dòng có đơn hàng';
								|ru = 'Выберите строки с распоряжениями';
								|en = 'Select lines with references'; fa = 'Select lines with references';
								|it = 'Selezionare le righe con le disposizioni';
								|pl = 'Wybierz wiersze z zamówieniami';
								|tr = 'Emir satırlarını seç'");
			ShowMessageBox(, MessageText);
			Return False;
			
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

&AtServer
Procedure SetHeadersByDeliveryType()
	
	If DeliveryKind = Enums.DeliveryKinds.FromWarehouse Then
		
		Items.DeliveryReferencesDate.Title = NStr("vi = 'Ngày giao hàng';
													|ru = 'Дата отгрузки';
													|en = 'Shipment date'; fa = 'تاریخ ارسال';
													|it = 'Data di spedizione';
													|pl = 'Data wysyłki';
													|tr = 'Sevkiyat tarihi'");
		Items.DeliveryReferencesTime.Title = NStr("vi = 'Thời gian giao hàng mong muốn';
													|ru = 'Желаемое время доставки';
													|en = 'Required delivery time'; fa = 'زمان تحویل لازم';
													|it = 'Orario di consegna preferibile';
													|pl = 'Pożądany czas dostawy';
													|tr = 'İstenilen teslimat süresi'");
		Items.DeliveryOrdersRecipientSender.Title = NStr("vi = 'Người nhận';
														|ru = 'Получатель';
														|en = 'Recipient'; fa = 'گیرنده';
														|it = 'Destinatario';
														|pl = 'Recipient';
														|tr = 'Alıcı'");
		
	Else
		
		Items.DeliveryReferencesDate.Title = NStr("vi = 'Ngày tiếp nhận';
													|ru = 'Дата поступления';
													|en = 'Date of receipt'; fa = 'تاریخ دریافت';
													|it = 'Data di ricezione';
													|pl = 'Data wpływu';
													|tr = 'Giriş tarihi'");
		Items.DeliveryReferencesTime.Title = NStr("vi = 'Thời gian chuyển hàng';
													|ru = 'Время передачи товара';
													|en = 'Goods delivery time'; fa = 'Goods delivery time';
													|it = 'Tempo di consegna merce';
													|pl = 'Czas przekazania towaru';
													|tr = 'Ürün transfer tarihi'");
		Items.DeliveryOrdersRecipientSender.Title = NStr("vi = 'Người gửi';
														|ru = 'Отправитель';
														|en = 'Sender'; fa = 'فرستنده';
														|it = 'Mittente';
														|pl = 'Sender';
														|tr = 'Gönderen'");
		
	EndIf;
	
EndProcedure

&AtServer
Function SaveResults()
	
	Goods = GoodsDelivery.CopyCollectionColumns(ReferenceGoodsToDeliver,
		"ReferenceOrder,Warehouse,RecipientSender,Products,Characteristic,Purpose,Series,Count,AllGoods");
	References = GoodsDelivery.CopyCollectionColumns(DeliveryReferences,
		"ReferenceOrder,Warehouse,Weight,VolumeM3,TimeFrom,TimeTo,RecipientSender,Carrier,AdditionalInformation,
		|Zone,Address,FieldValueAddress");
	
	TheStructureOfTheSearch = New Structure("IDInReferenceTree", 0);
	SelectedRows = Items.DeliveryReferences.SelectedRows;
	For Each Id In SelectedRows Do // Number
		
		TheStructureOfTheSearch.IDInReferenceTree = Id;
		CommandLine_ = References.Add();
		FillPropertyValues(CommandLine_, DeliveryReferences.FindByID(Id));
		FoundProductLines = ReferenceGoodsToDeliver.FindRows(TheStructureOfTheSearch);
		For Each Page1 In FoundProductLines Do
			FillPropertyValues(Goods.Add(), Page1);
		EndDo;
		
	EndDo;
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("ReferenceAddress", PutToTempStorage(References, OwnerGUID));
	ReturnStructure.Insert("AddressOfGoods", PutToTempStorage(Goods, OwnerGUID));
	Return ReturnStructure;
	
EndFunction

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
	If Item.Name = "sh_ShamsiInput_F_DateOfOrders_" Then
		DateOfOrders_OnChange(Items.DateOfOrders_);
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
