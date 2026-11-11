
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MethodParameters = New Structure();
	MethodParameters.Insert("ControlledLotReference", Parameters.ControlledLotReference);
	MethodParameters.Insert("Warehouse", Parameters.Warehouse);
	MethodParameters.Insert("Date", Parameters.Date);
	Actions = Enums.ActionsOnGoodsInQualityControlCertificate.GetChoiceData(MethodParameters);
	
	CurrentRow = Actions.FindByValue(Parameters.CurrentRow);
	If CurrentRow <> Undefined Then
		ValueSelected = CurrentRow.Value;
	Else
		ValueSelected = Actions[0].Value;
	EndIf;
	
	CurrentAction1 = Actions.FindByValue(Enums.ActionsOnGoodsInQualityControlCertificate.Unlock);
	Visible = CurrentAction1 <> Undefined;
	Items.SelectUnlockValue.Enabled = Visible;
	Items.UnlockHint.Enabled = Visible;
	
	If GetFunctionalOption("UseGoodsQuality") Then
		CurrentAction1 = Actions.FindByValue(Enums.ActionsOnGoodsInQualityControlCertificate.RegisterStockQualityChange);
		Visible = CurrentAction1 <> Undefined;
		Items.SelectValueToMakeDamage.Enabled = Visible;
		Items.HintToMakeDamage.Enabled = Visible;
	Else
		Items.SelectValueToMakeDamage.Visible = False;
		Items.HintToMakeDamage.Visible = False;
	EndIf;
	
	CurrentAction1 = Actions.FindByValue(Enums.ActionsOnGoodsInQualityControlCertificate.RegisterReturn);
	Visible = CurrentAction1 <> Undefined;
	Items.SelectIssueReturnValue.Enabled = Visible;
	Items.HintToMakeReturn.Enabled = Visible;
	
	If GetFunctionalOption("UseGoodsTransfer") Then
		
		CurrentAction1 = Actions.FindByValue(Enums.ActionsOnGoodsInQualityControlCertificate.RegisterGoodsTransfer);
		Visible = CurrentAction1 <> Undefined;
		Items.SelectValueToMakeMove.Enabled = Visible;
		Items.HintToMakeMove.Enabled = Visible;
		
	Else
		
		Items.SelectValueToMakeMove.Visible = False;
		Items.HintToMakeMove.Visible = False;
		
	EndIf;
	
	CurrentAction1 = Actions.FindByValue(Enums.ActionsOnGoodsInQualityControlCertificate.MakeDebit);
	Visible = CurrentAction1 <> Undefined;
	Items.SelectValueIssueWriteOff.Enabled = Visible;
	Items.HintToMakeWriteOff.Enabled = Visible;
	
	If GetFunctionalOption("UseWarehouseManagementSystem") Then
		
		TitleText =
			NStr("vi = 'Đã quyết định ghi giảm hàng hóa đã nhập tại kho.
				|Thích hợp để chọn cho hàng hóa không đạt chất lượng, cũng như các mẫu bị hủy.
				|Tiếp theo, chứng từ ""Ghi giảm hao hụt hàng hóa"" sẽ được lập theo quy trình thông thường.
				|Khi không phản ánh thừa/thiếu theo chứng từ phiếu, cần phải chỉ định lô hàng được kiểm soát.';
				|ru = 'Принято решение списать поступивший товар на складе.
				|Уместно выбирать, для некачественных товаров, а также разрушенных образцов.
				|Далее штатно оформляется документ ""Списание недостач товаров"".
				|При не ордерном отражении излишков/недостач в документе необходимо указать контролируемую партию.';
				|en = 'It was decided to write off the received goods in the warehouse.
				|You can select it for low-quality goods, as well as destroyed samples.
				|Next, create the ""Stock shortage recognition"" document.
				|If you do not use warehouse management upon recording surpluses/shortages, specify the controlled lot in the document.'; fa = 'تصمیم گرفته شد کالای دریافتی در انبار اسقاط شود.
				|می‌توانید این گزینه را برای کالای بی‌کیفیت و نیز نمونه‌های معدوم‌شده انتخاب کنید.
				|سپس سند «شناسایی کسری موجودی» را ایجاد کنید.
				|اگر هنگام ثبت مازاد/کسری از مدیریت انبار استفاده نمی‌کنید، لات کنترل‌شده را در سند مشخص کنید.';
				|it = 'It was decided to write off the received goods in the warehouse.
				|You can select it for low-quality goods, as well as destroyed samples.
				|Next, create the ""Stock shortage recognition"" document.
				|If you do not use warehouse management upon recording surpluses/shortages, specify the controlled lot in the document.';
				|pl = 'It was decided to write off the received goods in the warehouse.
				|You can select it for low-quality goods, as well as destroyed samples.
				|Next, create the ""Stock shortage recognition"" document.
				|If you do not use warehouse management upon recording surpluses/shortages, specify the controlled lot in the document.';
				|tr = 'Gelen ürünün ambarda gider yazılmasına karar verildi. 
				| Kalitesiz ürünler ve ayrıca yok edilen numuneler için seçilmesi uygundur. 
				|Standart prosedürde ""Ürün Eksiği Giderme"" belgesi düzenlenir. 
				| Fazlalıkların/eksikliklerin emir bazlı olmayan kaydında belgede kontrol edilen lotun belirtilmesi gerekir.'");
		
	Else
		
		TitleText =
			NStr("vi = 'Đã quyết định ghi giảm hàng hóa đã nhập tại kho.
				|Thích hợp để chọn cho hàng hóa không đạt chất lượng, cũng như các mẫu bị hủy.
				|Tiếp theo, chứng từ ""Ghi giảm hao hụt hàng hóa"" sẽ được lập theo quy trình thông thường.
				|Trong chứng từ cần phải chỉ định lô hàng được kiểm soát.';
				|ru = 'Принято решение списать поступивший товар на складе.
				|Уместно выбирать, для некачественных товаров, а также разрушенных образцов.
				|Далее штатно оформляется документ ""Списание недостач товаров"".
				|В документе необходимо указать контролируемую партию.';
				|en = 'It was decided to write off the received goods in the warehouse.
				|You can select it for low-quality goods, as well as destroyed samples.
				|Next, create the ""Stock shortage recognition"" document.
				|Specify the controlled lot in the document.'; fa = 'It was decided to write off the received goods in the warehouse.
				|You can select it for low-quality goods, as well as destroyed samples.
				|Next, create the ""Stock shortage recognition"" document.
				|Specify the controlled lot in the document.';
				|it = 'It was decided to write off the received goods in the warehouse.
				|You can select it for low-quality goods, as well as destroyed samples.
				|Next, create the ""Stock shortage recognition"" document.
				|Specify the controlled lot in the document.';
				|pl = 'It was decided to write off the received goods in the warehouse.
				|You can select it for low-quality goods, as well as destroyed samples.
				|Next, create the ""Stock shortage recognition"" document.
				|Specify the controlled lot in the document.';
				|tr = 'Ambara girişi yapılmış ürünün stoktan düşülmesine karar verildi. 
				| Kalitesiz ürünler ve imha edilen örnekler için uygundur. 
				| Ardından standart olarak ""Ürün eksikliklerinin stoktan düşülmesi"" belgesi düzenlenir. 
				| Belgede kontrole tabi lot belirtilmelidir.'");
		
	EndIf;
	
	Items.HintToMakeWriteOff.Title = TitleText;
	
	If GetFunctionalOption("UseGoodsQuality")
			And GetFunctionalOption("UseWarehouseManagementSystem") Then
		
		CurrentAction1 = Actions.FindByValue(Enums.ActionsOnGoodsInQualityControlCertificate.ChangeQuality);
		Visible = CurrentAction1 <> Undefined;
		Items.SelectValueChangeQuality.Enabled = Visible;
		Items.HintToChangeQuality.Enabled = Visible;
		
	Else
		
		Items.SelectValueChangeQuality.Visible = False;
		Items.HintToChangeQuality.Visible = False;
		
	EndIf;
	
	CurrentAction1 = Actions.FindByValue(Enums.ActionsOnGoodsInQualityControlCertificate.ToReturnToVendor);
	Visible = CurrentAction1 <> Undefined;
	Items.SelectValueReturnToSupplier.Enabled = Visible;
	Items.HintToReturnToSupplier.Enabled = Visible;
	
	CurrentAction1 = Actions.FindByValue(Enums.ActionsOnGoodsInQualityControlCertificate.DoNotReceiveGoods);
	Visible = CurrentAction1 <> Undefined;
	Items.SelectValueDoNotReceiveGoods.Enabled = Visible;
	Items.HintDonTReceiveGoods.Enabled = Visible;
	
	FillInExplanation();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectUnlockValueOnChange(Item)
	FillInExplanationOnClient();
EndProcedure

&AtClient
Procedure SelectValueDoNotReceiveGoodsOnChange(Item)
	FillInExplanationOnClient();
EndProcedure

&AtClient
Procedure SelectValueReturnToSupplierOnChange(Item)
	FillInExplanationOnClient();
EndProcedure

&AtClient
Procedure SelectValueChangeQualityOnChange(Item)
	FillInExplanationOnClient();
EndProcedure

&AtClient
Procedure SelectValueIssueWriteOffOnChange(Item)
	FillInExplanationOnClient();
EndProcedure

&AtClient
Procedure SelectValueToMakeMoveOnChange(Item)
	FillInExplanationOnClient();
EndProcedure

&AtClient
Procedure SelectIssueReturnValueOnChange(Item)
	FillInExplanationOnClient();
EndProcedure

&AtClient
Procedure SelectValueToMakeDamageOnChange(Item)
	FillInExplanationOnClient();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	NotifyChoice(ValueSelected);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInExplanation()
	
	Explanation = "";
	Visible = ValueSelected = Enums.ActionsOnGoodsInQualityControlCertificate.Unlock
		And Parameters.QualityCheckResult = Enums.GoodsQualityCheckResults.DamagedDuringResearch;
	
	Items.GroupRemark.Visible = Visible;
	If Visible Then
		Explanation = StrTemplate(NStr("vi = 'Thao tác đã chọn ""%1"" không tương ứng với kết quả kiểm tra chất lượng ""%2"".';
										|ru = 'Выбранное действие ""%1"" не соотносится с результатом проверки качества ""%2"".';
										|en = 'The selected ""%1"" action does not correlate with the result of the ""%2"" quality check.'; fa = 'The selected ""%1"" action does not correlate with the result of the ""%2"" quality check.';
										|it = 'The selected ""%1"" action does not correlate with the result of the ""%2"" quality check.';
										|pl = 'The selected ""%1"" action does not correlate with the result of the ""%2"" quality check.';
										|tr = 'Seçilen ""%1"" eylemi, ""%2"" kalite kontrol sonucuyla ilişkili değil.'"),
			Actions.FindByValue(ValueSelected).Presentation, Parameters.QualityCheckResult);
	Else
		Explanation = "";
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInExplanationOnClient()
	
	Explanation = "";
	Visible = ValueSelected = Enums.ActionsOnGoodsInQualityControlCertificate.Unlock
		And Parameters.QualityCheckResult = Enums.GoodsQualityCheckResults.DamagedDuringResearch;
	
	Items.GroupRemark.Visible = Visible;
	If Visible Then
		Explanation = StrTemplate(NStr("vi = 'Thao tác đã chọn ""%1"" không tương ứng với kết quả kiểm tra chất lượng ""%2"".';
										|ru = 'Выбранное действие ""%1"" не соотносится с результатом проверки качества ""%2"".';
										|en = 'The selected ""%1"" action does not correlate with the result of the ""%2"" quality check.'; fa = 'The selected ""%1"" action does not correlate with the result of the ""%2"" quality check.';
										|it = 'The selected ""%1"" action does not correlate with the result of the ""%2"" quality check.';
										|pl = 'The selected ""%1"" action does not correlate with the result of the ""%2"" quality check.';
										|tr = 'Seçilen ""%1"" eylemi, ""%2"" kalite kontrol sonucuyla ilişkili değil.'"),
			Actions.FindByValue(ValueSelected).Presentation, Parameters.QualityCheckResult);
	Else
		Explanation = "";
	EndIf;
	
EndProcedure

#EndRegion