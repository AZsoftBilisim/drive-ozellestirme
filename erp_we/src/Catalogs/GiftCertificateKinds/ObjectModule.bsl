#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	For Each TSRow In GiftCertificateCodeTemplates Do
		
		If CardType = Enums.CardTypes.Magnetic Then
			TSRow.BarcodeLength = 0;
			TSRow.StartOfBarcodeRange = "";
			TSRow.EndOfBarcodeRange = "";
		EndIf;
		
		If CardType = Enums.CardTypes.Barcode_ Then
			TSRow.MagneticCodeLength = 0;
			TSRow.StartOfMagneticCodeRange = "";
			TSRow.EndOfMagneticCodeRange = "";
			TSRow.MagneticStripeCardTemplate = Undefined;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	For Each TSRow In GiftCertificateCodeTemplates Do
		
		If CardType = Enums.CardTypes.Magnetic
			Or CardType = Enums.CardTypes.Mixed Then
			
			If Not ValueIsFilled(TSRow.MagneticCodeLength) Then
				Continue;
			EndIf;
			
			If StrLen(TSRow.StartOfMagneticCodeRange) > TSRow.MagneticCodeLength Then
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong dòng %1 danh sách ""Khuôn mẫu mã thẻ khách hàng thân thiết"" số lượng ký tự biên dưới của dải mã từ vượt quá chiều dài của mã từ.';
																					|ru = 'В строке %1 списка ""Шаблоны кодов карт лояльности"" количество символов нижней границы диапазона магнитного кода превышает длину магнитного кода.';
																					|en = 'In line %1 of the ""Templates of loyalty card codes"" list, number of characters in the lower bound of the magnetic code range exceeds the magnetic code length.'; fa = 'In line %1 of the ""Templates of loyalty card codes"" list, number of characters in the lower bound of the magnetic code range exceeds the magnetic code length.';
																					|it = 'Nella riga %1 dell''elenco ""Modelli di codici delle carte fedeltà"" Il numero di caratteri del limite inferiore dell''intervallo del codice magnetico supera la lunghezza del codice magnetico.';
																					|pl = 'W wierszu %1 listy ""Шаблоны кодов карт лояльности"" ilość symboli dolnej granicy zakresu kodu magnetycznego przekracza długość kodu magnetycznego.';
																					|tr = '""Sadakat Kartı Kod Şablonları"" listesinin %1 satırında, manyetik kod aralığının alt sınırındaki karakter sayısı manyetik kodun uzunluğunu aşmaktadır.'"), TSRow.LineNumber),
					ThisObject,
					CommonClientServer.PathToTabularSection("GiftCertificateCodeTemplates", TSRow.LineNumber, "StartOfMagneticCodeRange"),
					,
					Cancel);
			EndIf;
			
			If StrLen(TSRow.EndOfMagneticCodeRange) > TSRow.MagneticCodeLength Then
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong dòng %1 danh sách ""Khuôn mẫu mã thẻ khách hàng thân thiết"" số lượng ký tự biên trên của dải mã từ vượt quá chiều dài của mã từ.';
																					|ru = 'В строке %1 списка ""Шаблоны кодов карт лояльности"" количество символов верхней границы диапазона магнитного кода превышает длину магнитного кода.';
																					|en = 'In line %1 of the ""Templates of loyalty card codes"" list, number of characters in the upper bound of magnetic code range exceeds the magnetic code length.'; fa = 'In line %1 of the ""Templates of loyalty card codes"" list, number of characters in the upper bound of magnetic code range exceeds the magnetic code length.';
																					|it = 'Nella riga %1 dell''elenco ""Modelli di codici delle carte fedeltà"" Il numero di caratteri del limite superiore dell''intervallo del codice magnetico supera la lunghezza del codice magnetico.';
																					|pl = 'W wierszu %1 listy ""Шаблоны кодов карт лояльности"" ilość symboli górnej granicy zakresu kodu magnetycznego przekracza długość kodu magnetycznego.';
																					|tr = '""Sadakat Kartı Kod Şablonları"" listesinin %1 satırında, manyetik kod aralığının üst sınırındaki karakter sayısı manyetik kodun uzunluğunu aşmaktadır.'"), TSRow.LineNumber),
					ThisObject,
					CommonClientServer.PathToTabularSection("GiftCertificateCodeTemplates", TSRow.LineNumber, "EndOfMagneticCodeRange"),
					,
					Cancel);
			EndIf;
			
			If TSRow.EndOfMagneticCodeRange < TSRow.StartOfMagneticCodeRange Then
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong dòng %1 danh sách ""Khuôn mẫu mã thẻ khách hàng thân thiết"" biên dưới của khoảng mã thẻ từ vượt quá biên trên của khoảng mã từ.';
																					|ru = 'В строке %1 списка ""Шаблоны кодов карт лояльности"" нижняя граница диапазона магнитного кода превышает верхнюю границу диапазона магнитного кода.';
																					|en = 'In line %1 of the ""Templates of loyalty card codes"" list, the lower bound of the magnetic code range exceeds the upper bound of the magnetic code range.'; fa = 'In line %1 of the ""Templates of loyalty card codes"" list, the lower bound of the magnetic code range exceeds the upper bound of the magnetic code range.';
																					|it = 'Nella riga %1 dell''elenco ""Modelli di codici delle carte fedeltà"" Il limite inferiore dell''intervallo del codice magnetico supera il limite superiore dell''intervallo del codice magnetico.';
																					|pl = 'W wierszu %1 listy ""Шаблоны кодов карт лояльности"" górna granica zakresu kodu magnetycznego przekracza górną granicę zakresu kodu magnetycznego.';
																					|tr = '""Sadakat Kartı Kod Şablonları"" listesinin %1 satırında, manyetik kod aralığının alt sınırı, manyetik kod aralığının üst sınırını aşmaktadır.'"), TSRow.LineNumber),
					ThisObject,
					CommonClientServer.PathToTabularSection("GiftCertificateCodeTemplates", TSRow.LineNumber, "StartOfBarcodeRange"),
					,
					Cancel);
			EndIf;
			
		EndIf;
		
		If CardType = Enums.CardTypes.Barcode_
			Or CardType = Enums.CardTypes.Mixed Then
			
			If Not ValueIsFilled(TSRow.BarcodeLength) Then
				Continue;
			EndIf;
			
			If StrLen(TSRow.StartOfBarcodeRange) > TSRow.BarcodeLength Then
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong dòng %1 danh sách ""Khuôn mẫu mã thẻ khách hàng thân thiết"" số lượng ký tự biên dưới của dải mã vạch vượt quá chiều dài của mã vạch.';
																					|ru = 'В строке %1 списка ""Шаблоны кодов карт лояльности"" количество символов нижней границы диапазона штрихкода превышает длину штрихкода.';
																					|en = 'In line %1 of the ""Templates of loyalty card codes"" list, number of characters in the lower bound of the barcode range is greater than the barcode length.'; fa = 'In line %1 of the ""Templates of loyalty card codes"" list, number of characters in the lower bound of the barcode range is greater than the barcode length.';
																					|it = 'Nella riga %1 dell''elenco ""Modelli di codici delle carte fedeltà"" Il numero di caratteri del limite inferiore dell''intervallo del codice a barre supera la lunghezza del codice a barre.';
																					|pl = 'W wierszu %1 listy ""Шаблоны кодов карт лояльности"" ilość symboli dolnej granicy zakresu kodu kreskowego przekracza długość kodu kreskowego.';
																					|tr = '""Sadakat Kartı Kod Şablonları"" listesinin %1 satırında, barkod aralığının alt sınırındaki karakter sayısı barkodun uzunluğunu aşmaktadır.'"), TSRow.LineNumber),
					ThisObject,
					CommonClientServer.PathToTabularSection("GiftCertificateCodeTemplates", TSRow.LineNumber, "StartOfBarcodeRange"),
					,
					Cancel);
			EndIf;
			
			If StrLen(TSRow.EndOfBarcodeRange) > TSRow.BarcodeLength Then
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong dòng %1 danh sách ""Khuôn mẫu mã thẻ khách hàng thân thiết"" số lượng ký tự biên trên của dải mã vạch vượt quá chiều dài của mã vạch.';
																					|ru = 'В строке %1 списка ""Шаблоны кодов карт лояльности"" количество символов верхней границы диапазона штрихкода превышает длину штрихкода.';
																					|en = 'In line %1 of the ""Templates of loyalty card codes"" list, number of characters in the upper bound of the barcode range is greater than the barcode length.'; fa = 'In line %1 of the ""Templates of loyalty card codes"" list, number of characters in the upper bound of the barcode range is greater than the barcode length.';
																					|it = 'Nella riga %1 dell''elenco ""Modelli di codici delle carte fedeltà"" Il numero di caratteri del limite superiore dell''intervallo del codice a barre supera la lunghezza del codice a barre.';
																					|pl = 'W wierszu %1 listy ""Шаблоны кодов карт лояльности"" ilość symboli górnej granicy zakresu kodu kreskowego przekracza długość kodu kreskowego.';
																					|tr = '""Sadakat Kartı Kod Şablonları"" listesinin %1 satırında, barkod aralığının üst sınırındaki karakter sayısı barkodun uzunluğunu aşmaktadır.'"), TSRow.LineNumber),
					ThisObject,
					CommonClientServer.PathToTabularSection("GiftCertificateCodeTemplates", TSRow.LineNumber, "EndOfBarcodeRange"),
					,
					Cancel);
			EndIf;
			
			If TSRow.EndOfBarcodeRange < TSRow.StartOfBarcodeRange Then
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong dòng %1 của danh sách ""Khuôn mẫu mã thẻ khách hàng thân thiết"" biên dưới của khoảng mã vạch vượt quá biên trên của khoảng mã vạch.';
																					|ru = 'В строке %1 списка ""Шаблоны кодов карт лояльности"" нижняя граница диапазона штрихкода превышает верхнюю границу диапазона штрихкода.';
																					|en = 'In line %1 of the ""Templates of loyalty card codes"" list, the lower bound of the barcode range exceeds the upper bound of the barcode range.'; fa = 'In line %1 of the ""Templates of loyalty card codes"" list, the lower bound of the barcode range exceeds the upper bound of the barcode range.';
																					|it = 'Nella riga %1 dell''elenco ""Modelli di codici delle carte fedeltà"" Il limite inferiore dell''intervallo del codice a barre supera il limite superiore dell''intervallo del codice a barre.';
																					|pl = 'W wierszu %1 listy ""Шаблоны кодов карт лояльности"" dolna granica zakresu kodu kreskowego przekracza górną granicę zakresu kodu kreskowego.';
																					|tr = '""Sadakat Kartı Kod Şablonları"" listesinin %1 satırında, barkod aralığının alt sınırı, barkod aralığının üst sınırını aşmaktadır.'"), TSRow.LineNumber),
					ThisObject,
					CommonClientServer.PathToTabularSection("GiftCertificateCodeTemplates", TSRow.LineNumber, "StartOfBarcodeRange"),
					,
					Cancel);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	NotCheckedAttributeArray = New Array;
	If CardType = Enums.CardTypes.Magnetic Then
		NotCheckedAttributeArray.Add("GiftCertificateCodeTemplates.BarcodeLength");
		NotCheckedAttributeArray.Add("GiftCertificateCodeTemplates.StartOfBarcodeRange");
		NotCheckedAttributeArray.Add("GiftCertificateCodeTemplates.EndOfBarcodeRange");
	EndIf;
	If CardType = Enums.CardTypes.Barcode_ Then
		NotCheckedAttributeArray.Add("GiftCertificateCodeTemplates.MagneticCodeLength");
		NotCheckedAttributeArray.Add("GiftCertificateCodeTemplates.StartOfMagneticCodeRange");
		NotCheckedAttributeArray.Add("GiftCertificateCodeTemplates.EndOfMagneticCodeRange");
		NotCheckedAttributeArray.Add("GiftCertificateCodeTemplates.MagneticStripeCardTemplate");
	EndIf;
	
	If GiftCardAccounting25 Then
		CheckedAttributes.Add("Organization");
		CheckedAttributes.Add("CashFlowItemSale");
		CheckedAttributes.Add("CashFlowItemReturn");
		UseFinancialAccountingGroups = GetFunctionalOption("UseFinancialAccountingGroups");
		If UseFinancialAccountingGroups Then
			CheckedAttributes.Add("FinancialAccountingGroup");
		EndIf;
	EndIf;
	
	ControlDimensionFilling = Common.ObjectAttributeValue(IncomeItem, "ControlDimensionFilling");
	If ControlDimensionFilling = True Then
		CheckedAttributes.Add("DimensionOfRevenue");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If Cancel Or DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
