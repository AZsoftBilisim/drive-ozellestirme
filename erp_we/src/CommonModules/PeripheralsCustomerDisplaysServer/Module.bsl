
#Region Internal

// Adds the supplied drivers to the list as part of the configuration.
// 
// Parameters:
//  DriversOfHardware - See EquipmentManager.NewTableOfSuppliedHardwareDrivers
//
Procedure UpdateSuppliedDrivers(DriversOfHardware) Export
	
	Driver = DriversOfHardware.Add();
	Driver.EquipmentType = Enums.PeripheralTypes.CustomerDisplay;
	Driver.NameOfDriver  = "Driver1CBuyerDisplay";
	Driver.Description = NStr("vi = '1C:Màn hình khách hàng';
								|ru = '1С:Дисплей покупателя';
								|en = '1C:Customer display'; fa = '1C:Customer display';
								|it = '1С:Display dell''acquirente';
								|pl = '1C:Wyświetlacz nabywcy';
								|tr = '1C:Customer display'", CommonCEL.DefaultLanguageCode());
	Driver.ObjectID = "CustomerDisplayEx"; 
	Driver.RecommendedUse = True;
	
	// ++ Non-mobile application
	// -- Non-mobile application     
	
EndProcedure

// Prepare the operation data.
// 
// Parameters:
//  ConnectionParameters - Structure -Connection setting
//  Command - String - Command
//  OperationParametersList - Structure -Operation parameters
// 
// Returns:
//  Undefined
Function PrepareOperationData(ConnectionParameters, Command, OperationParametersList) Export
	
	OperationData = OperationParametersBuyerDisplays(); 
	OperationData.HTMLText = "<p>No information</p>";
	OperationData.OperationStatus = OperationParametersList.OperationStatus;
	OperationData.LinesOfText = OperationParametersList.LinesOfText;

	// ++ Non-mobile application
	If Command = "DisplayInfo" Then      
		
		If OperationParametersList.Operation = "ServiceMode" Then
			ServiceModePage(ConnectionParameters, OperationData, OperationParametersList);
		ElsIf OperationParametersList.Operation = "Information" Then   
			InformationPage(ConnectionParameters, OperationData, OperationParametersList);
		ElsIf OperationParametersList.Operation = "PaymentOperation" Then   
			PaymentOfOperationPage(ConnectionParameters, OperationData, OperationParametersList);
		ElsIf OperationParametersList.Operation = "GoodsList" Then 
			ProductListPage(ConnectionParameters, OperationData, OperationParametersList);
		ElsIf OperationParametersList.Operation = "FiscalCheck" Then
			FiscalReceiptPage(ConnectionParameters, OperationData, OperationParametersList);
		ElsIf OperationParametersList.Operation = "AgeVerification" Then
			AgeVerificationPage(ConnectionParameters, OperationData, OperationParametersList);
		ElsIf OperationParametersList.Operation = "Picture" Then
			PicturePage(ConnectionParameters, OperationData, OperationParametersList);
		EndIf;
		
		If Not IsBlankString(OperationParametersList.QRCodeValue) Then
			OperationData.QRCodeValue = OperationParametersList.QRCodeValue;
		EndIf;
			
	EndIf;
	
	OperationData.Insert("CodeStatusOfOperation", OperationStatusOnDisplay(OperationParametersList.OperationStatus));
	OperationData.Insert("WorkplaceStatusCode", OperationParametersList.WorkplaceStatusCode);
	// -- Non-mobile application 
	
	Return OperationData;       
	
EndFunction

Procedure ProcessOperationData(ConnectionParameters, Command, ExecutionResult, OperationData) Export
	
EndProcedure

#EndRegion

#Region Private   

// Fill in the operation structure
// 
// Returns:
//  Structure - Operation parameters:
// * Result - Boolean
// * ErrorText - String
Function OperationParametersBuyerDisplays()
	
	OperationParametersList = New Structure();
	OperationParametersList.Insert("Result", True); 
	OperationParametersList.Insert("LinesOfText");    
	OperationParametersList.Insert("QRCodeValue"); // String - QR code value
	OperationParametersList.Insert("PictureQRCode"); // String - a string with a base64 representation of the png image of the logo.      
	OperationParametersList.Insert("OperationStatus", 0); // Number - Status: 0-Not installed, 1-Completed successfully, 2-Operation failed
	OperationParametersList.Insert("WorkplaceStatusCode");
	OperationParametersList.Insert("ErrorText");     
	OperationParametersList.Insert("HTMLText");
	Return OperationParametersList;
	
EndFunction 

// ++ Non-mobile application 

// The Status code of the operation is displayed.
// 
// Parameters:    
//   OperationStatus - EnumRef.OperationStatusOnDisplay - Status of operation on display
//   
// Returns:
//   Number - Status code.
//
Function OperationStatusOnDisplay(OperationStatus) Export
	
	If OperationStatus = Undefined Then
		StatusCode_ = 0
	Else
		StatusesOfOperation = New Map(); 
		StatusesOfOperation.Insert(Enums.OperationStatusOnDisplay.ExecutedSuccessfully   , 0);
		StatusesOfOperation.Insert(Enums.OperationStatusOnDisplay.ExecutedSuccessfully   , 1);
		StatusesOfOperation.Insert(Enums.OperationStatusOnDisplay.ActionNotExecuted, 2);
		StatusesOfOperation.Insert(Enums.OperationStatusOnDisplay.AwaitingOperation   , 3);
		StatusesOfOperation.Insert(Enums.OperationStatusOnDisplay.Information         , 4);
		StatusCode_ = StatusesOfOperation.Get(OperationStatus);
	EndIf;
	
	Return StatusCode_;
	
EndFunction

#Region OutputInformation

Function BuyerSDisplayTemplateParameters()
	
	Result = New Structure();
	Result.Insert("PageHeader", "");
	Result.Insert("Title", "");
	Result.Insert("Operation", "");
	Result.Insert("LongDesc", "");
	Result.Insert("Picture", "");
	Result.Insert("Information", "");
	Result.Insert("Comment", "");
	Result.Insert("QRCode", "");
	Result.Insert("OperationStatus", Enums.OperationStatusOnDisplay.EmptyRef());
	Result.Insert("MyTaxApp", False);
	Result.Insert("TextMyTaxApplication", "");
	Result.Insert("MyTaxIcon", False);
	Result.Insert("MyTaxButton", False);
	Result.Insert("TextMyTaxButton", "");
	Result.Insert("Buttons", New Array());
	Return Result;
	
EndFunction

Function HTMLTextBasedOnBuyerSDisplayTemplate(ConnectionParameters, TemplateParameters)
	
	DisplayWorksOutClicks = ConnectionParameters.DisplayWorksOutClicks;
	Template = EquipmentManagerCached.ContentsOfGeneralTemplate("CustomerDisplayTemplate");
	Template = StrReplace(Template, "%TITLE%", TemplateParameters.PageHeader);
	Template = StrReplace(Template, "%CAPTION%", TemplateParameters.Title);
	Template = StrReplace(Template, "%OPERATION%", TemplateParameters.Operation);
	Template = StrReplace(Template, "%DESC%", TemplateParameters.LongDesc);
	Template = StrReplace(Template, "%INFO%", TemplateParameters.Information);
	Template = StrReplace(Template, "%COMMENT%", TemplateParameters.Comment);
	Template = StrReplace(Template, "%QR%", TemplateParameters.QRCode);
	
	If IsBlankString(TemplateParameters.QRCode) Then
		OperationStatus = TemplateParameters.OperationStatus;
		If OperationStatus = Enums.OperationStatusOnDisplay.ExecutedSuccessfully Then
			Template = StrReplace(Template, "<!--STATUS_OK", "");
			Template = StrReplace(Template, "STATUS_OK-->", "");
		ElsIf OperationStatus = Enums.OperationStatusOnDisplay.ActionNotExecuted Then
			Template = StrReplace(Template, "<!--STATUS_FAIL", "");
			Template = StrReplace(Template, "STATUS_FAIL-->", "");
		ElsIf OperationStatus = Enums.OperationStatusOnDisplay.AwaitingOperation Then
			Template = StrReplace(Template, "<!--STATUS_WAIT", "");
			Template = StrReplace(Template, "STATUS_WAIT-->", "");
		ElsIf OperationStatus = Enums.OperationStatusOnDisplay.Information Then
			Template = StrReplace(Template, "<!--STATUS_INFO", "");
			Template = StrReplace(Template, "STATUS_INFO-->", "");
		EndIf;
	EndIf;
	
	ButtonsTemplate = "";
	If ConnectionParameters.DisplayWorksOutClicks Then
		
		If TemplateParameters.Buttons.Count()>0 Then
			CharactersInButton = 10; // minimum button size
			For Each Button In TemplateParameters.Buttons Do // Structure
				CharactersInButton = Max(CharactersInButton, StrLen(Button.Description));
			EndDo;
			OptimalButtonWidth = CharactersInButton * 20;
			OneButtonTemplate = "<button style=""width: %1px"" onclick = ""%2"">%3</button>";
			SeparatorTemplate = "<span class=""button_separate"">&nbsp</span>";
			
			IndexOf = 0;
			For Each Button In TemplateParameters.Buttons Do // Structure
				ButtonsTemplate = ButtonsTemplate + StrTemplate(OneButtonTemplate, OptimalButtonWidth, Button.Id, Button.Description);
				If IndexOf < TemplateParameters.Buttons.UBound() Then
					ButtonsTemplate = ButtonsTemplate + SeparatorTemplate;
				EndIf;
				IndexOf = IndexOf + 1;
			EndDo;
		EndIf;
		
	EndIf;
	Template = StrReplace(Template, "%BUTTONS%", ButtonsTemplate);
	
	Return Template;
	
	
EndFunction

Function HTMLTextImageAccordingToBuyerSDisplayTemplate(ConnectionParameters, TemplateParameters)
	
	DisplayWorksOutClicks = ConnectionParameters.DisplayWorksOutClicks;
	Template = EquipmentManagerCached.ContentsOfGeneralTemplate("BuyerSDisplayTemplatePicture");
	Template = StrReplace(Template, "%IMAGE%", TemplateParameters.Picture);
	
	ButtonsTemplate = "";
	If ConnectionParameters.DisplayWorksOutClicks Then
		
		If TemplateParameters.Buttons.Count()>0 Then
			CharactersInButton = 10; // minimum button size
			For Each Button In TemplateParameters.Buttons Do // Structure
				CharactersInButton = Max(CharactersInButton, StrLen(Button.Description));
			EndDo;
			OptimalButtonWidth = CharactersInButton * 20;
			OneButtonTemplate = "<button style=""width: %1px"" onclick = ""%2"">%3</button>";
			SeparatorTemplate = "<span class=""button_separate"">&nbsp</span>";
			
			IndexOf = 0;
			For Each Button In TemplateParameters.Buttons Do // Structure
				ButtonsTemplate = ButtonsTemplate + StrTemplate(OneButtonTemplate, OptimalButtonWidth, Button.Id, Button.Description);
				If IndexOf < TemplateParameters.Buttons.UBound() Then
					ButtonsTemplate = ButtonsTemplate + SeparatorTemplate;
				EndIf;
				IndexOf = IndexOf + 1;
			EndDo;
		EndIf;
		
	EndIf;
	Template = StrReplace(Template, "%BUTTONS%", ButtonsTemplate);
	
	Return Template;
	
	
EndFunction

Procedure AgeVerificationPage(Val ConnectionParameters, Val OperationData, Val OperationParametersList)
	
	
EndProcedure

Procedure ServiceModePage(Val ConnectionParameters, Val OperationData, Val OperationParametersList)
	
	Parameters = BuyerSDisplayTemplateParameters();
	Parameters.Title = XMLString(OperationParametersList.CompanyName);
	If OperationParametersList.ReadinessToWork Then
		Parameters.Operation = NStr("vi = 'SẴN SÀNG BÁN';
									|ru = 'ГОТОВ К ПРОДАЖЕ';
									|en = 'READY FOR SALE'; fa = 'READY FOR SALE';
									|it = 'ГОТОВ К ПРОДАЖЕ';
									|pl = 'READY FOR SALE';
									|tr = 'SATIŞA HAZIR'");
		Parameters.Information = NStr("vi = 'CHÀO MỪNG!';
										|ru = 'ДОБРО ПОЖАЛОВАТЬ!';
										|en = 'WELCOME'; fa = 'WELCOME';
										|it = 'ДОБРО ПОЖАЛОВАТЬ!';
										|pl = 'WITAMY!';
										|tr = 'HOŞ GELDİNİZ!'"); // APK: 374 - Interface feature
		Parameters.OperationStatus = Enums.OperationStatusOnDisplay.ExecutedSuccessfully;
	ElsIf Not OperationParametersList.ReadinessToWork Then
		Parameters.Operation = NStr("vi = 'KHÔNG HỢP LỆ';
									|ru = 'НЕДОСТУПНО';
									|en = 'UNAVAILABLE'; fa = 'UNAVAILABLE';
									|it = 'НЕДОСТУПНО';
									|pl = 'UNAVAILABLE';
									|tr = 'MEVCUT DEĞİL'");
		Parameters.Information = NStr("vi = 'QUẦY THU NGÂN KHÔNG HOẠT ĐỘNG!';
										|ru = 'КАССА НЕ РАБОТАЕТ!';
										|en = 'THE CASH REGISTER IS DOWN.'; fa = 'THE CASH REGISTER IS DOWN.';
										|it = 'КАССА НЕ РАБОТАЕТ!';
										|pl = 'THE CASH REGISTER IS DOWN.';
										|tr = 'KASA ÇALIŞMIYOR!'"); // APK: 374 - Interface feature
		Parameters.OperationStatus = Enums.OperationStatusOnDisplay.ActionNotExecuted;
	Else
		Parameters.Operation = NStr("vi = 'KHÔNG HỢP LỆ';
									|ru = 'НЕДОСТУПНО';
									|en = 'UNAVAILABLE'; fa = 'UNAVAILABLE';
									|it = 'НЕДОСТУПНО';
									|pl = 'UNAVAILABLE';
									|tr = 'MEVCUT DEĞİL'");
		Parameters.Information = NStr("vi = 'CHẾ ĐỘ DỊCH VỤ';
										|ru = 'СЕРВИСНЫЙ РЕЖИМ';
										|en = 'SERVICE MODE'; fa = 'SERVICE MODE';
										|it = 'СЕРВИСНЫЙ РЕЖИМ';
										|pl = 'SERVICE MODE';
										|tr = 'HİZMET MODU'");
		Parameters.OperationStatus = Enums.OperationStatusOnDisplay.AwaitingOperation;
	EndIf;
	
	
	OperationData.HTMLText = HTMLTextBasedOnBuyerSDisplayTemplate(ConnectionParameters, Parameters);
	OperationData.OperationStatus = Parameters.OperationStatus;
	// text to the regular customer display
	If IsBlankString(OperationParametersList.LinesOfText) Then
		OperationData.LinesOfText = Parameters.Information; 
	EndIf;
	
EndProcedure

Procedure InformationPage(Val ConnectionParameters, Val OperationData, Val OperationParametersList)
	
	LinesOfText = OperationParametersList.LinesOfText;
	LinesOfText = StrReplace(LinesOfText, Chars.LF, "<br>"); 
	
	Parameters = BuyerSDisplayTemplateParameters();
	Parameters.Title = XMLString(OperationParametersList.CompanyName);
	Parameters.Operation = NStr("vi = 'THÔNG TIN';
								|ru = 'ИНФОРМАЦИЯ';
								|en = 'INFORMATION'; fa = 'INFORMATION';
								|it = 'ИНФОРМАЦИЯ';
								|pl = 'INFORMATION';
								|tr = 'BİLGİLER'");
	Parameters.Information = LinesOfText;
	Parameters.QRCode = OperationParametersList.PictureBase64;
	Parameters.OperationStatus = OperationParametersList.OperationStatus;
	For Each Button In OperationParametersList.Buttons Do
		Parameters.Buttons.Add(Button);
	EndDo;
	OperationData.HTMLText = HTMLTextBasedOnBuyerSDisplayTemplate(ConnectionParameters, Parameters);
	
EndProcedure

Procedure FiscalReceiptPage(Val ConnectionParameters, Val OperationData, Val OperationParametersList)
	
	PictureBase64 = "";
	If ValueIsFilled(OperationParametersList.QRCodeValue) Then
		Size = 400;
		PictureBase64 = PictureOfBase64QRCode(OperationParametersList.QRCodeValue, Size);
	EndIf;
	
	Parameters = BuyerSDisplayTemplateParameters();
	Parameters.Title = NStr("vi = 'Nhận phiếu điện tử';
							|ru = 'Получите электронный чек';
							|en = 'Receive an electronic receipt'; fa = 'Receive an electronic receipt';
							|it = 'Получите электронный чек';
							|pl = 'Receive an electronic receipt';
							|tr = 'Elektronik fiş alın'");
	Parameters.Operation = NStr("vi = 'XIN CẢM ƠN';
								|ru = 'СПАСИБО ЗА ПОКУПКУ';
								|en = 'THANK YOU FOR YOUR PURCHASE'; fa = 'THANK YOU FOR YOUR PURCHASE';
								|it = 'СПАСИБО ЗА ПОКУПКУ';
								|pl = 'THANK YOU FOR YOUR PURCHASE';
								|tr = 'SATIN ALIMINIZ İÇİN TEŞEKKÜRLER'");
	Parameters.LongDesc = NStr("vi = 'Hãy quét mã QR <br> trong ứng dụng di động';
								|ru = 'Сканируйте QR-код <br> в мобильном приложении';
								|en = 'Scan the QR code<br> in the mobile application'; fa = 'Scan the QR code<br> in the mobile application';
								|it = 'Сканируйте QR-код <br> в мобильном приложении';
								|pl = 'Scan the QR code<br> in the mobile application';
								|tr = 'Mobil uygulamada <br> QR kodunu tarayın'");
	Parameters.QRCode = PictureBase64;
	Parameters.MyTaxIcon = True;
	Parameters.MyTaxButton = True;
	Parameters.TextMyTaxButton = NStr("vi = 'In bản sao phiếu';
										|ru = 'Напечатать копию чека';
										|en = 'Print receipt copy'; fa = 'چاپ نسخه رسید';
										|it = 'Напечатать копию чека';
										|pl = 'Print receipt copy';
										|tr = 'Çekin kopyasını yazdır'");
	OperationData.HTMLText = HTMLTextBasedOnBuyerSDisplayTemplate(ConnectionParameters, Parameters);
	
	If IsBlankString(OperationParametersList.LinesOfText) Then
		OperationData.LinesOfText = NStr("vi = 'CẢM ƠN VÌ ĐÃ MUA HÀNG!';
										|ru = 'СПАСИБО ЗА ПОКУПКУ!';
										|en = 'THANK YOU FOR YOUR PURCHASE'; fa = 'THANK YOU FOR YOUR PURCHASE';
										|it = 'СПАСИБО ЗА ПОКУПКУ!';
										|pl = 'DZIĘKUJĘ ZA ZAKUP!';
										|tr = 'SATIN ALIMINIZ İÇİN TEŞEKKÜRLER!'");
	EndIf;
	
EndProcedure

Procedure ProductListPage(Val ConnectionParameters, Val OperationData, Val OperationParametersList)
	
	Width = 10;
	StringPattern = "";  
	TitleTemplate1 = "<tr>"; 
	TakeOutBasementDiscount = False;
	NumberFormat_ = NumberFormat_(ConnectionParameters.DisplayDisplaysHTML);
	NumberFormatTable = TableNumberFormat(ConnectionParameters.DisplayDisplaysHTML);
	
	TabularSectionColumns = OperationParametersList.TabularSectionColumns;
	For Each TabularSectionColumn In OperationParametersList.TabularSectionColumns Do                                        
		If Upper(TabularSectionColumn.Name) = NStr("vi = 'CHIẾT KHẤU';
													|ru = 'СКИДКА';
													|en = 'DISCOUNT'; fa = 'DISCOUNT';
													|it = 'СКИДКА';
													|pl = 'DISCOUNT';
													|tr = 'İNDİRİM'") Then
			TakeOutBasementDiscount = True;
		EndIf;
		Width       = String(?(TabularSectionColumn.Width > 0, TabularSectionColumn.Width, 10));
		ColumnName   = TabularSectionColumn.Name;   
		Title    = ?(IsBlankString(TabularSectionColumn.Title), ColumnName, TabularSectionColumn.Title);
		Align = AlignmentString(TabularSectionColumn.Align);
		
		TitleTemplate1 = TitleTemplate1
			+ StrTemplate("<td %1 width=""%2"">%3</td>", Align, Width + "%", Title);
		StringPattern = StringPattern 
			+ StrTemplate("<td %1 width=""%2"">%3</td>", Align, Width + "%", "%" + ColumnName + "%");
	EndDo;                                                        
	TitleTemplate1 = TitleTemplate1  + "</tr>";
	
	TabularSection = "";
	CurrentRow = 1;
	RowsCount = OperationParametersList.TabularSection.Count();
	For Each StringTabularSection In OperationParametersList.TabularSection Do 
		
		IsLastRow = (CurrentRow = RowsCount);
		StringText = StrTemplate("<tr %1>", ?(IsLastRow, "position_anchor=""true"" style=""background: #D5EAFF""", "")) + StringPattern;
		For Each TableRow In StringTabularSection Do    
			StringText = StrReplace(StringText, "%" + TableRow.Key + "%", TableRow.Value);
		EndDo;            
		StringText = StringText + "</tr>";
		TabularSection = TabularSection + StringText;
		CurrentRow = CurrentRow + 1;
	EndDo;     
	
	BasementDiscount = "";
	If TakeOutBasementDiscount Or OperationParametersList.BasementDiscount > 0 Then
		BasementDiscount = StrTemplate("<tr><td align=""right"" colspan=""%1"">%2</td><td align=""right"" width=""%3"">%4</td></tr>", 
			TabularSectionColumns.Count() - 1, 
			NStr("vi = 'Chiết khấu';
				|ru = 'Скидка';
				|en = 'Discount'; fa = 'تخفیف';
				|it = 'Скидка';
				|pl = 'Discount';
				|tr = 'İndirim'"),
			Width + "%",
			Format(OperationParametersList.BasementDiscount, NumberFormatTable));
	EndIf;
	TableFooter = BasementDiscount + StrTemplate("<tr><td align=""right"" colspan=""%1"">%2</td><td align=""right"" width=""%3"">%4</td></tr>", 
		TabularSectionColumns.Count() - 1, 
		NStr("vi = 'Tổng số';
			|ru = 'Итого';
			|en = 'Total'; fa = 'جمع کل';
			|it = 'Итого';
			|pl = 'Total';
			|tr = 'Toplam'"),
		Width + "%",
		Format(OperationParametersList.Basement, NumberFormatTable));
	
	TemplateCustomerDisplays = EquipmentManagerCached.ContentsOfGeneralTemplate("CustomerDisplayTemplateForReceipt");
	TemplateCustomerDisplays = StrReplace(TemplateCustomerDisplays, "<!--Head-->" , TitleTemplate1);
	TemplateCustomerDisplays = StrReplace(TemplateCustomerDisplays, "<!--Table-->", TabularSection);
	TemplateCustomerDisplays = StrReplace(TemplateCustomerDisplays, "<!--Foot-->" , TableFooter);
	TemplateCustomerDisplays = StrReplace(TemplateCustomerDisplays, "%COMMENT%", "");
	
	OperationData.HTMLText = TemplateCustomerDisplays;
	// text to the regular customer display
	If IsBlankString(OperationParametersList.LinesOfText) Then
		OperationData.LinesOfText = NStr("vi = 'Tổng số:';
										|ru = 'ИТОГО:';
										|en = 'TOTAL:'; fa = 'TOTAL:';
										|it = 'ИТОГО:';
										|pl = 'TOTAL:';
										|tr = 'TOPLAM:'") + " " + Format(OperationParametersList.Basement, NumberFormat_);  
	EndIf;

EndProcedure

Procedure PaymentOfOperationPage(Val ConnectionParameters, Val OperationData, Val OperationParametersList)
	
	Parameters = BuyerSDisplayTemplateParameters();
	Parameters.Operation = StatusText(OperationParametersList);
	Parameters.Title = TextOfPaymentSystemType(OperationParametersList);
	
	PaymentViaService = False;
	If OperationParametersList.PaymentSystemType = Enums.TypesOfCashRegisterPaymentSystem.InstantPayments  Then
		Parameters.Comment = NStr("vi = 'Để thanh toán, hãy quét mã QR';
									|ru = 'Для совершения платежа отсканируйте QR-код';
									|en = 'Scan the QR code to pay'; fa = 'Scan the QR code to pay';
									|it = 'Для совершения платежа отсканируйте QR-код';
									|pl = 'Aby dokonać płatności zeskanuj kod QR';
									|tr = 'Ödeme yapmak için QR kodu taratın'");
		PaymentViaService = True;
	ElsIf OperationParametersList.PaymentSystemType = Enums.TypesOfCashRegisterPaymentSystem.YooKassa Then
		Parameters.Comment = NStr("vi = 'Để đăng nhập vào tài khoản cá nhân, hãy quét mã QR';
									|ru = 'Для входа в личный кабинет отсканируйте QR-код';
									|en = 'To log in to your personal account, scan the QR code'; fa = 'To log in to your personal account, scan the QR code';
									|it = 'Для входа в личный кабинет отсканируйте QR-код';
									|pl = 'To log in to your personal account, scan the QR code';
									|tr = 'Kişisel hesabınıza girmek için QR kodunu tarayın'");
		PaymentViaService = True;
	EndIf;
	
	Parameters.OperationStatus = OperationParametersList.OperationStatus;
	If PaymentViaService 
		And OperationParametersList.OperationStatus = Enums.OperationStatusOnDisplay.AwaitingOperation Then
		If ValueIsFilled(OperationParametersList.QRCodeValue) Then
			Size = 300;
			Parameters.QRCode = PictureOfBase64QRCode(OperationParametersList.QRCodeValue, Size);
		EndIf;
	EndIf; 
	
	If IsBlankString(OperationParametersList.AdditionalText) Then
		NumberFormat_ = NumberFormat_(ConnectionParameters.DisplayDisplaysHTML);
		If WithdrawChange(OperationParametersList) Then
			Parameters.LongDesc = NStr("vi = 'TIỀN THỪA';
										|ru = 'СДАЧА';
										|en = 'CHANGE'; fa = 'CHANGE';
										|it = 'СДАЧА';
										|pl = 'CHANGE';
										|tr = 'PARA ÜSTÜ'");
			Parameters.Information = Format(OperationParametersList.Change_2, NumberFormat_);
		Else
			Parameters.LongDesc = NStr("vi = 'SỐ TIỀN';
										|ru = 'СУММА';
										|en = 'AMOUNT'; fa = 'AMOUNT';
										|it = 'СУММА';
										|pl = 'AMOUNT';
										|tr = 'TUTAR'");
			Parameters.Information = Format(OperationParametersList.Sum, NumberFormat_);
		EndIf;   
	Else
		Parameters.LongDesc = OperationParametersList.AdditionalText;
	EndIf;
	
	OperationData.HTMLText = HTMLTextBasedOnBuyerSDisplayTemplate(ConnectionParameters, Parameters);
	// text to the regular customer display
	If IsBlankString(OperationParametersList.LinesOfText) Then
		OperationData.LinesOfText = NStr("vi = 'GIAO DỊCH THANH TOÁN';
										|ru = 'ПЛАТЕЖНАЯ ОПЕРАЦИЯ';
										|en = 'PAYMENT TRANSACTION'; fa = 'PAYMENT TRANSACTION';
										|it = 'ПЛАТЕЖНАЯ ОПЕРАЦИЯ';
										|pl = 'OPERACJA PŁATNICZA';
										|tr = 'ÖDEME İŞLEMİ'") + Chars.LF + Parameters.Operation;
	EndIf;

EndProcedure

Procedure PicturePage(Val ConnectionParameters, Val OperationData, Val OperationParametersList)
	
	BinaryData = True;
	
	Parameters = BuyerSDisplayTemplateParameters();
	LinesOfText = OperationParametersList.LinesOfText;
	LinesOfText = StrReplace(LinesOfText, Chars.LF, "<br>"); 
	Parameters.Information = LinesOfText;
	Parameters.Picture = OperationParametersList.PictureBase64;
	
	OperationData.HTMLText = HTMLTextImageAccordingToBuyerSDisplayTemplate(ConnectionParameters, Parameters);
	
EndProcedure

Function WithdrawChange(OperationParametersList)
	
	Result = (OperationParametersList.OperationStatus = Enums.OperationStatusOnDisplay.ExecutedSuccessfully
		Or OperationParametersList.OperationStatus = Enums.OperationStatusOnDisplay.AwaitingOperation);
	Result = Result And OperationParametersList.PaymentByCash And OperationParametersList.Change_2 > 0;
	Return Result;
	
EndFunction

Function TextOfPaymentSystemType(Val OperationParametersList)
	
	PaymentSystemType = "";
	If OperationParametersList.PaymentByCash Then
		If OperationParametersList.Return Then
			PaymentSystemType = NStr("vi = 'TIỀN MẶT';
									|ru = 'НАЛИЧНЫЕ';
									|en = 'CASH'; fa = 'CASH';
									|it = 'НАЛИЧНЫЕ';
									|pl = 'CASH';
									|tr = 'NAKİT'"); 
		Else
			PaymentSystemType = NStr("vi = 'THANH TOÁN TIỀN MẶT';
									|ru = 'НАЛИЧНАЯ ОПЛАТА';
									|en = 'CASH PAYMENT'; fa = 'CASH PAYMENT';
									|it = 'НАЛИЧНАЯ ОПЛАТА';
									|pl = 'CASH PAYMENT';
									|tr = 'NAKİT ÖDEMESİ'"); 
		EndIf;
	ElsIf Not IsBlankString(OperationParametersList.PaymentSystemType) Then
		PaymentSystemType = String(OperationParametersList.PaymentSystemType)
	Else
		If OperationParametersList.Return Then
			PaymentSystemType = NStr("vi = 'TRẢ LẠI BẰNG CHUYỂN KHOẢN';
									|ru = 'БЕЗНАЛИЧНЫЙ ВОЗВРАТ';
									|en = 'BANK ACCOUNT REFUND'; fa = 'BANK ACCOUNT REFUND';
									|it = 'БЕЗНАЛИЧНЫЙ ВОЗВРАТ';
									|pl = 'BANK ACCOUNT REFUND';
									|tr = 'BANKA HESABI İADESİ'"); 
		Else
			PaymentSystemType = NStr("vi = 'THANH TOÁN CHUYỂN KHOẢN';
									|ru = 'БЕЗНАЛИЧНАЯ ОПЛАТА';
									|en = 'NON-CASH PAYMENT'; fa = 'NON-CASH PAYMENT';
									|it = 'БЕЗНАЛИЧНАЯ ОПЛАТА';
									|pl = 'NON-CASH PAYMENT';
									|tr = 'ELEKTRONİK ÖDEME'");      
		EndIf;
	EndIf;
	Return PaymentSystemType;

EndFunction

Function StatusText(Val OperationParametersList)
	
	Status_Text = "";
	If OperationParametersList.OperationStatus = Enums.OperationStatusOnDisplay.ExecutedSuccessfully Then
		Status_Text = NStr("vi = 'THÀNH CÔNG';
							|ru = 'УСПЕШНО';
							|en = 'SUCCESS'; fa = 'SUCCESS';
							|it = 'УСПЕШНО';
							|pl = 'SUCCESS';
							|tr = 'BAŞARILI'");
	ElsIf OperationParametersList.OperationStatus = Enums.OperationStatusOnDisplay.ActionNotExecuted Then
		Status_Text = NStr("vi = 'TỪ CHỐI';
							|ru = 'ОТКАЗ';
							|en = 'CANCEL'; fa = 'CANCEL';
							|it = 'ОТКАЗ';
							|pl = 'CANCEL';
							|tr = 'SORUMLULUK REDDİ'");
	ElsIf OperationParametersList.OperationStatus = Enums.OperationStatusOnDisplay.AwaitingOperation Then
		If OperationParametersList.Return Then
			Status_Text = NStr("vi = 'ĐỢI TRẢ LẠI KHOẢN THANH TOÁN';
								|ru = 'ОЖИДАНИЕ ВОЗВРАТА ОПЛАТЫ';
								|en = 'WAITING FOR REFUND'; fa = 'WAITING FOR REFUND';
								|it = 'ОЖИДАНИЕ ВОЗВРАТА ОПЛАТЫ';
								|pl = 'WAITING FOR REFUND';
								|tr = 'TERS İBRAZ BEKLENİYOR'");
		Else
			Status_Text = NStr("vi = 'CHỜ THANH TOÁN';
								|ru = 'ОЖИДАНИЕ ОПЛАТЫ';
								|en = 'WAITING FOR PAYMENT'; fa = 'WAITING FOR PAYMENT';
								|it = 'ОЖИДАНИЕ ОПЛАТЫ';
								|pl = 'WAITING FOR PAYMENT';
								|tr = 'ÖDEME BEKLENİYOR'");
		EndIf;
	ElsIf OperationParametersList.OperationStatus = Enums.OperationStatusOnDisplay.Information Then
		Status_Text = NStr("vi = 'THÔNG TIN';
							|ru = 'ИНФОРМАЦИЯ';
							|en = 'INFORMATION'; fa = 'INFORMATION';
							|it = 'ИНФОРМАЦИЯ';
							|pl = 'INFORMATION';
							|tr = 'BİLGİLER'");
	EndIf;
	Return Status_Text;

EndFunction

Function AlignmentString(Align)
	
	If Align = HorizontalAlign.Left Then 
		Result = "align=""left""";
	ElsIf Align = HorizontalAlign.Right Then 
		Result = "align=""right""";
	Else
		Result = "align=""center""";
	EndIf;
	
	Return Result;
	
EndFunction

Function NumberFormat_(Val DisplayDisplaysHTML)
	
	If DisplayDisplaysHTML Then
		NumberFormat_ = "NFD=2; NDS=.; NZ=0.00";
	Else
		NumberFormat_ = "NFD=2; NDS=.; NZ=0.00; NG=0";
	EndIf;
	
	Return NumberFormat_;
	
EndFunction

Function TableNumberFormat(Val DisplayDisplaysHTML)
	
	If DisplayDisplaysHTML Then
		NumberFormatTable = "NDS=.;ND=12;NFD=2;NZ=0.00;NG=0";
	Else
		NumberFormatTable = "NDS=.;ND=12;NFD=2;NZ=0.00;NG=0";
	EndIf;
	
	Return NumberFormatTable;
	
EndFunction

Function PictureOfBase64QRCode(Val QRCodeValue, Val Size)
	
	BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();
	BarcodeParameters.Width = Size;
	BarcodeParameters.Height = Size;
	BarcodeParameters.CodeType = 16; // QR
	BarcodeParameters.Barcode = QRCodeValue;
	BarcodeParameters.RemoveExtraBackground = True;
	ResultBarcode = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters);
	PictureBase64 = Base64String(ResultBarcode.BinaryData);
	Return PictureBase64;

EndFunction

#EndRegion

// -- Non-mobile application 

#EndRegion