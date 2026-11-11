
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core	

	// Prohibit editing
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	Items.Country.Visible = GetFunctionalOption("UseMultiCountryAccounting");
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core	
	
	OnReadCreateAtServer();
	
	TypeOfInitialBid = CurrentObject.RateType;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetVisibilityByBidType();
	UpdateButtonAvailability();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If TypeOfInitialBid = PredefinedValue("Enum.TypesOfExcisableCategoryRates.FixedRate")
		And Object.RateType <> PredefinedValue("Enum.TypesOfExcisableCategoryRates.FixedRate")
		And ThereIsDataInRegister
		And Not ThereIsAnAgreement Then
		
		QueryText = NStr("vi = 'Không nên thay đổi kiểu thuế suất từ cố định sang thuế suất theo giá trị, vì có thể đã có các khoản tính toán dựa trên thuế suất này. Nếu tiếp tục, thì toàn bộ lịch sử thuế suất theo thể loại này sẽ bị xóa. Tiếp tục?';
						|ru = 'Не рекомендуется менять тип ставки с твердой на адвалорную, т.к. по ней могут быть начисления. Если продолжить, то будет удалена вся история ставок по данной категории. Продолжить?';
						|en = 'We do not recommend that you change the rate type from fixed to ad valorem, as there may be accruals on it. If you continue, the entire rate history for this category will be deleted. Continue?'; fa = 'We do not recommend that you change the rate type from fixed to ad valorem, as there may be accruals on it. If you continue, the entire rate history for this category will be deleted. Continue?';
						|it = 'We do not recommend that you change the rate type from fixed to ad valorem, as there may be accruals on it. If you continue, the entire rate history for this category will be deleted. Continue?';
						|pl = 'We do not recommend that you change the rate type from fixed to ad valorem, as there may be accruals on it. If you continue, the entire rate history for this category will be deleted. Continue?';
						|tr = 'Oran tipini sabitten ad valorem esasına çevirmeniz önerilmemektedir, çünkü bu türde ek ücretler olabilir. Devam ederseniz, bu kategorideki tüm oran geçmişi silinecektir. Devam edilsin mi?'");
		
		ShowQueryBox(New CallbackDescription("ContinueWriteCompletion", ThisObject),
			QueryText,
			QuestionDialogMode.YesNo);
			
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(Object.Ref) Then
		UnitOfMeasurementBeforeChange = Common.ObjectAttributeValue(Object.Ref, "UnitOfMeasure");
	EndIf;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
	
	ObjectAttributesLock.LockAttributes(ThisObject);
		
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If CurrentObject.RateType = Enums.TypesOfExcisableCategoryRates.FixedRate Then
		
		Category = CurrentObject.Ref;
		ExciseTaxData = BidByCategoryAsOfDate(Category, DateFrom1);
		If Not ValueIsFilled(ExciseTaxData.Period) Or ExciseTaxData.Rate1 <> Rate1 Then
			
			InformationRegisters.RatesOfExcisableGoodsCategories.SetBidByCategory(Category, Rate1, DateFrom1);
			
		ElsIf ExciseTaxData.Period <> DateFrom1 Then
			
			Cancel = True;
			MessageText = StrTemplate(NStr("vi = 'Theo dạng hàng hóa chịu thuế TTĐB này, mức thuế suất tương ứng đã được áp dụng kể từ %1.';
											|ru = 'По данному виду подакцизного товара уже действует данная ставка с %1.';
											|en = 'For this type of excisable goods, this rate is already in effect from %1.'; fa = 'For this type of excisable goods, this rate is already in effect from %1.';
											|it = 'For this type of excisable goods, this rate is already in effect from %1.';
											|pl = 'For this type of excisable goods, this rate is already in effect from %1.';
											|tr = 'Bu tür tüketim vergisine tabi ürünler malları için, bu oran %1 oranından itibaren zaten geçerlidir.'"), Format(ExciseTaxData.Period,"DLF=D" ));
			If ValueIsFilled(UnitOfMeasurementBeforeChange) And Object.UnitOfMeasure <> UnitOfMeasurementBeforeChange Then
				MessageText = MessageText + StrTemplate(NStr("vi = 'Để thay đổi đơn vị tính của thuế TTĐB, cần chọn kỳ đã ghi nhận.';
															|ru = 'Для изменения единицы измерения акциза необходимо выбрать уже записанный период.';
															|en = 'To change the excise unit of measure, select an already saved period.'; fa = 'To change the excise unit of measure, select an already saved period.';
															|it = 'To change the excise unit of measure, select an already saved period.';
															|pl = 'To change the excise unit of measure, select an already saved period.';
															|tr = 'Tüketim vergisinin ölçü birimini değiştirmek için önceden kaydedilmiş bir dönem seçmeniz gerekmektedir.'"));
			EndIf;
			Common.MessageToUser(MessageText);
		EndIf;
		
	EndIf;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	UpdateCurrentData(False,True);
	Modified = False;
	TypeOfInitialBid = Object.RateType;
	
	// Prohibit editing
	ObjectAttributesLock.LockAttributes(ThisObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	UpdateButtonAvailability();
	Notify("Recording_ExciseCategory", Undefined, Object.Ref);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If (EventName = "Recording_RateOfExciseCategory"
		Or EventName = "Delete_RateOfExciseCategory")
		And Source = Object.Ref Then
		UpdateCurrentData(,, False);
		UpdateButtonAvailability();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.RateType = Enums.TypesOfExcisableCategoryRates.FixedRate Then
		
		If Not ValueIsFilled(DateFrom1) Then
			MessageText = CommonClientServer.FillingErrorText( , , Items.DateFrom1.Title);
			Common.MessageToUser(MessageText, , Items.DateFrom1, , Cancel);
		EndIf;
		
	EndIf;

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
Procedure DateFrom1OnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateCurrentData(,, False);
	UpdateButtonAvailability();
	
EndProcedure

&AtClient
Procedure RateTypeOnChange(Item)
	
	SetVisibilityByBidType();
	
EndProcedure

&AtClient
Procedure HistoryDescriptionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	If FormattedStringURL = "ChangeHistory" Then
		If Modified Then
			AskQuestionFormModified();
		Else
			OpenChangeHistory_();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure HistoryDescriptionClick(Item)
	
	If Modified Then
		AskQuestionFormModified();
	Else
		OpenChangeHistory_();
	EndIf;
	
EndProcedure

&AtClient
Procedure SumOnChange(Item)
	
	BidFromRegister = False;
	UpdateButtonAvailability();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)

	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateBidInformation(Command)
	
	UpdateCurrentData(,, False);
	UpdateButtonAvailability();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	DateFrom1 = CurrentSessionDate();
	TextColorIssue = StyleColors.TextColorIssue;
	ColorOfRecordText = StyleColors.FunctionsPanelSectionColor;
	
	UpdateCurrentData(True);
	
EndProcedure

&AtServer
Procedure UpdateCurrentData(ForCurrentPeriod = False, ToUpdateData = True, ToUpdatePeriod = True)
	
	If Object.RateType = Enums.TypesOfExcisableCategoryRates.FixedRate Then
		
		If ForCurrentPeriod Then
			SessionDate = CurrentSessionDate();
			If ToUpdatePeriod Then
				DateFrom1 = SessionDate;
			EndIf;
			Period = SessionDate;
		Else
			Period = DateFrom1;
		EndIf;
		
		TextDateBy = NStr("vi = 'hiệu lực vô thời hạn.';
							|ru = 'действует бессрочно.';
							|en = 'valid indefinitely.'; fa = 'valid indefinitely.';
							|it = 'valid indefinitely.';
							|pl = 'valid indefinitely.';
							|tr = 'süresiz olarak geçerlidir.'");
		ThereIsDataInRegister = False;
		BidFromRegister = False;
		
		If ValueIsFilled(Object.Ref) Then
			
			Result = BidByCategoryAsOfDate(Object.Ref, Period);
				
			If ValueIsFilled(Result.Period) Then
				
				ThereIsDataInRegister = True;
				
				If ToUpdateData Then
					If ToUpdatePeriod Then
						DateFrom1 = Result.Period;
					EndIf;
					Rate1 = Result.Rate1;
					BidFromRegister = True;
				EndIf;
			ElsIf ToUpdateData Then
				If ToUpdatePeriod And ValueIsFilled(Result.DateTo) Then
					DateFrom1 = Result.DateTo+1;
					UpdateCurrentData(False, True, True);
					Return;
				EndIf;
				Rate1 = 0;
			EndIf;
			
			HyperlinkText_ = NStr("vi = 'Lịch sử thay đổi';
									|ru = 'История изменений';
									|en = 'Change history'; fa = 'سابقه تغییرات';
									|it = 'Cronologia delle modifiche';
									|pl = 'Historia zmian';
									|tr = 'Değişiklik geçmişi'") + " (" + Result.NumberOfPeriods + ")";
			Items.HistoryDescription.Title = HyperlinkText_;
			Items.HistoryDescription.Visible = True;
			
			If ValueIsFilled(Result.DateTo) Then
				TextDateBy = NStr("vi = 'hợp lệ cho';
									|ru = 'действует по';
									|en = 'Valid until'; fa = 'معتبر تا';
									|it = 'in vigore fino a';
									|pl = 'Obowiązuje do';
									|tr = 'kadar geçerlidir'") + " " + Format(Result.DateTo, "DLF=DD");
			EndIf;
		
		Else
			Items.HistoryDescription.Visible = False;
		EndIf;
		
		Items.DateTo.Title = TextDateBy;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenChangeHistory_()
	
	FormParameters = New Structure("ReadOnly, ExcisableGoodsCategory", ReadOnly, Object.Ref);
	
	OpenForm("InformationRegister.RatesOfExcisableGoodsCategories.Form.EditHistory",
		FormParameters,
		ThisObject, , , ,
		New CallbackDescription("OpenChangeHistory_Completion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenChangeHistory_Completion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		DateFrom1 = Result;
		UpdateCurrentData(False, True);
		UpdateButtonAvailability();
	EndIf;
	
EndProcedure

&AtClient
Procedure AskQuestionFormModified()
	
	QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
					|ru = 'Данные были изменены. Сохранить изменения?';
					|en = 'The data has changed. Do you want to save the changes?'; fa = 'The data has changed. Do you want to save the changes?';
					|it = 'I dati sono stati modificati. Salvare le modifiche?';
					|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
					|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
	Notification = New CallbackDescription("OpenChangeHistory_Continued", ThisObject);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNoCancel);
	
EndProcedure

&AtClient
Procedure OpenChangeHistory_Continued(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		OpenChangeHistory_();
	ElsIf Result = DialogReturnCode.Yes Then
		If Not WriteChanges() Then
			Return;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function WriteChanges(Close = False)
	
	ClearMessages();
	Write();
	Return True;
	
EndFunction

&AtServerNoContext
Function BidByCategoryAsOfDate(ExcisableGoodsCategory, BidPeriod)
	
	Result = InformationRegisters.RatesOfExcisableGoodsCategories.BidByCategoryAsOfDate(
		ExcisableGoodsCategory, BidPeriod);
	
	Return Result;
	
EndFunction

&AtClient
Procedure UpdateButtonAvailability()
	
	If Not ThereIsDataInRegister
	Or Not ValueIsFilled(Object.Ref) Then
		Items.InformationOnData.TextColor = TextColorIssue;
		Items.Rate1.TextColor = TextColorIssue;
		Items.InformationOnData.Title = NStr("vi = 'Dữ liệu về thuế suất chưa được ghi lại';
											|ru = 'Данные по ставке не записаны';
											|en = 'Rate data is not saved'; fa = 'Rate data is not saved';
											|it = 'Rate data is not saved';
											|pl = 'Rate data is not saved';
											|tr = 'Oran verileri kaydedilmedi'");
	ElsIf Not BidFromRegister Then
		Items.InformationOnData.TextColor = TextColorIssue;
		Items.Rate1.TextColor = New Color;
		Items.InformationOnData.Title = NStr("vi = 'Dữ liệu về thuế suất đã thay đổi';
											|ru = 'Данные по ставке изменены';
											|en = 'Rate data is changed'; fa = 'Rate data is changed';
											|it = 'Rate data is changed';
											|pl = 'Rate data is changed';
											|tr = 'Oran verileri değiştirildi'");
	Else
		Items.InformationOnData.TextColor = ColorOfRecordText;
		Items.Rate1.TextColor = New Color;
		Items.InformationOnData.Title = NStr("vi = 'Dữ liệu về thuế suất đã được ghi lại';
											|ru = 'Данные по ставке записаны';
											|en = 'Rate data is saved'; fa = 'Rate data is saved';
											|it = 'Rate data is saved';
											|pl = 'Rate data is saved';
											|tr = 'Oran verileri kaydedildi'");
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVisibilityByBidType()

	If Object.RateType = PredefinedValue("Enum.TypesOfExcisableCategoryRates.FixedRate") Then
		Items.CurrentData.Visible = True;
		Items.AdValoremRateInformation.Visible = False;
	Else
		Items.CurrentData.Visible = False;
		Items.AdValoremRateInformation.Visible = True;
		
	EndIf;

EndProcedure

&AtClient
Procedure ContinueWriteCompletion(Result, AdditionalData) Export
	
	If Result = DialogReturnCode.Yes Then
		ThereIsAnAgreement = True;
		Write();
	Else
		Object.RateType = PredefinedValue("Enum.TypesOfExcisableCategoryRates.FixedRate");
		UpdateCurrentData(True, True);
		SetVisibilityByBidType();
	EndIf;
	
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
	If Item.Name = "sh_ShamsiInput_F_DateFrom1" Then
		DateFrom1OnChange(Items.DateFrom1);
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
