#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ListOfPricingOptions = Undefined;
	If Parameters.Property("ListOfPricingOptions",ListOfPricingOptions) Then
		
		VariantList = Items.SetTemporaryPrices.ChoiceList;
		VariantList.Clear();
		
		For Each Item In ListOfPricingOptions Do
			VariantList.Add(Item.Value, Item.Presentation);
		EndDo;
		
	EndIf;
	
	PriceStartDate = Parameters.PriceStartDate;
	MarketingActivity = Parameters.MarketingActivity;
	TheseArePricesWithAnExpirationDate = Parameters.TheseArePricesWithAnExpirationDate;
	
	If Not Parameters.Property("EndDateOfThePricePeriod", PriceExpirationDate) Then
		PriceExpirationDate = Parameters.PriceExpirationDate;
	EndIf;
	
	VisibilityOfApproval = GetFunctionalOption("UseApprovalOfItemPrices") 
		And Not UserRightsCached.PriceSetupWithoutApproval();
	Items.InformationLabelApproval.Visible = VisibilityOfApproval;
	
	HintTextPeriod = NStr("vi = 'Giới hạn thiết lập giá theo thời gian: đơn giá được thiết lập vào kỳ cụ thể,
		|sau khi kết thúc sẽ quay trở lại mức giá trước đó';
		|ru = 'Ограничивать установку цен периодом: цены устанавливаются на указанный период,
		|после окончания которого будут возвращены прежние цены';
		|en = 'Limit price setting to a period:  prices are set for the specified period.
		|Current prices will be returned after the end date'; fa = 'Limit price setting to a period:  prices are set for the specified period.
		|Current prices will be returned after the end date';
		|it = 'Limit price setting to a period:  prices are set for the specified period.
		|Current prices will be returned after the end date';
		|pl = 'Limit price setting to a period:  prices are set for the specified period.
		|Current prices will be returned after the end date';
		|tr = 'Fiyatların belirlenmesini belirli bir süre için sınırla: Fiyatlar belirli bir süre için ayarlanır,
		|bu sürenin sonunda önceki fiyatlara geri dönülür'");
	
	Items.PriceActionEndDateField.ToolTip = HintTextPeriod;
	Items.PriceActionEndDateField.ToolTipRepresentation = ToolTipRepresentation.Button;
	
	EventHintText = NStr("vi = 'Hoạt động marketing mà đơn  giá được thiết lập trong phạm vi đó';
						|ru = 'Маркетинговое мероприятие, в рамках которого устанавливаются цены';
						|en = 'Marketing activity within which prices are set'; fa = 'Marketing activity within which prices are set';
						|it = 'Marketing activity within which prices are set';
						|pl = 'Marketing activity within which prices are set';
						|tr = 'Fiyatların belirlendiği pazarlama faaliyeti'");
	
	Items.MarketingActivity.ToolTip = EventHintText;
	Items.MarketingActivity.ToolTipRepresentation = ToolTipRepresentation.Button;
	
	SetTemporaryPricesWhenChangingOnServer_(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormElementHandlers

&AtClient
Procedure DateOfPricesWhenChanged(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ThisObject.Title = TitleText(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Set(Command)
	
	ClearMessages();
	
	If TheseArePricesWithAnExpirationDate And PriceExpirationDate <= PriceStartDate Then
		MessageText = NStr("vi = 'Ngày hết kỳ hiệu lực của đơn giá phải lớn hơn ngày đầu kỳ.';
							|ru = 'Дата завершения периода действия цен должна быть больше начала периода.';
							|en = 'The price validity period end date must be greater than the period start.'; fa = 'The price validity period end date must be greater than the period start.';
							|it = 'La data di completamento del periodo di validità dei prezzi deve essere successiva all''inizio del periodo.';
							|pl = 'Data zakończenia terminu ważności cen powinna być większa niż początek okresu.';
							|tr = 'Fiyat geçerlilik döneminin sona erme tarihi, dönemin başlangıcından daha büyük olmalıdır.'");
		CommonClient.MessageToUser(MessageText,,,"PriceExpirationDate");
		Return;
	EndIf; 
	
	ReturnStructure = New Structure();
	ReturnStructure.Insert("Comment", Comment);
	ReturnStructure.Insert("PriceApplicationOption", PriceApplicationOption);
	If TheseArePricesWithAnExpirationDate And IsBlankString(Comment) Then
		ReturnStructure.Insert("Comment",Title);
	EndIf; 
	ReturnStructure.Insert("PriceStartDate", PriceStartDate);
	ReturnStructure.Insert("PriceExpirationDate", PriceExpirationDate);
	ReturnStructure.Insert("MarketingActivity", MarketingActivity);
	ReturnStructure.Insert("TheseArePricesWithAnExpirationDate", TheseArePricesWithAnExpirationDate);
	Close(ReturnStructure);
	
EndProcedure

&AtClient
Procedure SetTimePricesWhenChangesOccur(Item)
	SetTemporaryPricesWhenChangingOnServer_(ThisForm);
EndProcedure


&AtClientAtServerNoContext
Procedure SetTemporaryPricesWhenChangingOnServer_(Form)
	
	//The form.Elements.Install Time limits.Width 			= ?(Form.These are the prices of the period of action, 18, 11);	
	
	Form.Items.PriceActionDateSelectionGroup.Visible 	= Not Form.TheseArePricesWithAnExpirationDate;
	Form.Items.PriceValidityPeriodSelectionGroup.Visible 	= Form.TheseArePricesWithAnExpirationDate;
	Form.Items.MarketingActivity.Visible 		= Form.TheseArePricesWithAnExpirationDate;

	Form.Title = TitleText(Form);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Function TitleText(Form)

	If Form.TheseArePricesWithAnExpirationDate Then
		TitleText = NStr("vi = 'Đặt đơn giá tạm thời từ %1 đến %2';
						|ru = 'Установить временные цены с %1 по %2';
						|en = 'Set temporary prices from %1 to %2'; fa = 'Set temporary prices from %1 to %2';
						|it = 'Impostare prezzi temporanei da %1 a %2';
						|pl = 'Ustaw ceny tymczasowe z %1 na %2';
						|tr = 'Geçici fiyatları %1 ile %2 arası yapılandır'");
	Else
		TitleText = NStr("vi = 'Đặt đơn giá mới vào %1';
						|ru = 'Установить новые цены на %1';
						|en = 'Set new prices for %1'; fa = 'Set new prices for %1';
						|it = 'Impostare nuovi prezzi per %1';
						|pl = 'Ustaw nowe ceny na %1';
						|tr = '%1 için yeni fiyatları yapılandır'");
	EndIf;
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(TitleText,
		Format(Form.PriceStartDate,"DLF=D"),Format(Form.PriceExpirationDate, "DLF=D"));
	
	Return TitleText;

EndFunction // The text of the subtitle()
 

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
	If Item.Name = "sh_ShamsiInput_F_PriceStartDate" Then
		DateOfPricesWhenChanged(Items.PriceSettingDate);
	ElsIf Item.Name = "sh_ShamsiInput_F_PriceExpirationDate" Then
		DateOfPricesWhenChanged(Items.PriceActionEndDateField);
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
