
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PackageBarcodes.Load(Parameters.PackageBarcodes.Unload());
	
	For Each String In PackageBarcodes Do
		String.PackageType = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(String.PackageBarcode, "PackageType");
	EndDo;
	
	UpdateTotals();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Confirm(Command)
	Close = True;
	Close(PackageBarcodes);
EndProcedure

&AtClient
Procedure PackageBarcodesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.PackageBarcodes.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref", CurrentRow.PackageBarcode);
	
	ShowValue(,CurrentRow.PackageBarcode);
		
EndProcedure

Procedure UpdateTotals()
	
	Mark_ = 0;
	Mono = 0;
	Multi = 0;
	
	For Each String In PackageBarcodes Do
		
		If String.PackageType = Enums.PackageTypes.MarkedGoods Then
			Mark_ = Mark_ + 1;
		ElsIf String.PackageType = Enums.PackageTypes.SingleProductPackage Then
			Mono = Mono + 1;
		ElsIf String.PackageType = Enums.PackageTypes.MultiproductPackaging Then
			Multi = Multi + 1;
		EndIf;
		
	EndDo;
	
	Items.DecorationMarkedGoods.Title = StrTemplate(NStr("vi = 'Sản phẩm dán nhãn: %1';
														|ru = 'Маркированный товар: %1';
														|en = 'Marked goods: %1'; fa = 'Marked goods: %1';
														|it = 'Маркированный товар: %1';
														|pl = 'Marked goods: %1';
														|tr = 'İşaretlenmiş ürün: %1'"), Mark_);
	Items.DecorationMonoCommodityPackaging.Title = StrTemplate(NStr("vi = 'Bộ đóng gói một mặt hàng: %1';
																	|ru = 'Монотоварная упаковка: %1';
																	|en = 'Single product packaging unit: %1'; fa = 'Single product packaging unit: %1';
																	|it = 'Монотоварная упаковка: %1';
																	|pl = 'Single product packaging unit: %1';
																	|tr = 'Tek ürünlü paketleme ünitesi: %1'"), Mono);
	Items.DecorationMultiCommodityPackaging.Title = StrTemplate(NStr("vi = 'Bộ đóng gói nhiều mặt hàng: %1';
																	|ru = 'Мультитоварная упаковка: %1';
																	|en = 'Multiproduct packaging unit: %1'; fa = 'Multiproduct packaging unit: %1';
																	|it = 'Мультитоварная упаковка: %1';
																	|pl = 'Multiproduct packaging unit: %1';
																	|tr = 'Çok ürünlü paketleme ünitesi: %1'"), Multi);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	StandardProcessing = Close;
	Cancel = Not Close;
	
	If Not Close Then
		ValueList = New ValueList;
		ValueList.Add("Save", NStr("vi = 'Lưu lại';
									|ru = 'Сохранить';
									|en = 'Save'; fa = 'ذخیره';
									|it = 'Salvare';
									|pl = 'Save';
									|tr = 'Sakla'"));
		ValueList.Add("Close", NStr("vi = 'Không lưu lại';
									|ru = 'Без сохранения';
									|en = 'Do not save'; fa = 'Do not save';
									|it = 'Senza salvataggio';
									|pl = 'Bez zapisywania';
									|tr = 'Kaydetmeden'"));
		
		Notification = New CallbackDescription("AfterClosingQuestion_", ThisObject);
		ShowQueryBox(Notification, NStr("vi = 'Lưu lại các thay đổi?';
										|ru = 'Сохранить изменения?';
										|en = 'Save changes?'; fa = 'Save changes?';
										|it = 'Salvare le modifiche?';
										|pl = 'Zapisać zmiany?';
										|tr = 'Değişiklikler kaydededilsin mi?'"), ValueList, 0);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterClosingQuestion_(Result, Var_Parameters) Export
	
	Close = True;
	
	If Result = "Save" Then
		Close(PackageBarcodes);
	ElsIf Result = "Close" Then
		Close(Undefined);
	EndIf;
	
EndProcedure


&AtClient
Procedure PackageBarcodesAfterDeleteRow(Item)
	UpdateTotals();
EndProcedure

#EndRegion