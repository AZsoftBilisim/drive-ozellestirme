
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);
	
	CodeStartSelectionFromListOnServer();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Query = New Query(
	"SELECT TOP 1
	|	ItemsIDOfPeripheralsOffline.Code AS Code
	|FROM
	|	InformationRegister.ItemsIDOfPeripheralsOffline AS ItemsIDOfPeripheralsOffline
	|WHERE
	|	ItemsIDOfPeripheralsOffline.Code = &Code
	|	AND ItemsIDOfPeripheralsOffline.ExchangeRule = &ExchangeRule
	|	AND ItemsIDOfPeripheralsOffline.Products = VALUE(Catalog.Products.EmptyRef)
	|");
	
	Query.SetParameter("Code", CurrentObject.Code);
	Query.SetParameter("ExchangeRule", CurrentObject.ExchangeRule);
	
	If Not Query.Execute().IsEmpty() Then
		RecordToDelete = InformationRegisters.ItemsIDOfPeripheralsOffline.CreateRecordManager();
		RecordToDelete.Code = CurrentObject.Code;
		RecordToDelete.ExchangeRule = CurrentObject.ExchangeRule;
		RecordToDelete.Delete();
	EndIf;
	
	Code = OfflinePeripheralsServerCall.GetMaximumCode(Record.ExchangeRule)+1;
	While Code < CurrentObject.Code Do
		OfflinePeripheralsServerCall.DeleteCode(CurrentObject.ExchangeRule, Code);
		Code = Code+1;
	EndDo;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Record.SourceRecordKey.Code <> CurrentObject.Code Then
		OfflinePeripheralsServerCall.DeleteCode(CurrentObject.ExchangeRule, Record.SourceRecordKey.Code);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	Query = New Query(
	"SELECT TOP 1
	|	ItemsIDOfPeripheralsOffline.Code AS Code,
	|	ItemsIDOfPeripheralsOffline.Products AS Products,
	|	ItemsIDOfPeripheralsOffline.Characteristic AS Characteristic,
	|	ItemsIDOfPeripheralsOffline.Package AS Package,
	|	ItemsIDOfPeripheralsOffline.Products.Description AS ProductsPresentation,
	|	ItemsIDOfPeripheralsOffline.Characteristic.Description AS CharacteristicPresentation,
	|	ItemsIDOfPeripheralsOffline.Package.Description AS PackagePresentation
	|FROM
	|	InformationRegister.ItemsIDOfPeripheralsOffline AS ItemsIDOfPeripheralsOffline
	|WHERE
	|	ItemsIDOfPeripheralsOffline.Code = &Code
	|	AND ItemsIDOfPeripheralsOffline.Products <> VALUE(Catalog.Products.EmptyRef)
	|");
	
	Query.SetParameter("Code", Record.Code);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() // The barcode has already been recorded in the database
		And Record.SourceRecordKey.Code <> Record.Code Then
		
		ErrorDescription = NStr("vi = 'Mã này đã được dùng cho mặt hàng %Products%';
								|ru = 'Такой код уже назначен для номенклатуры %Products%';
								|en = 'Such code is already assigned for items %Products%'; fa = 'Such code is already assigned for items %Products%';
								|it = 'Questo codice è già impostato per l''articolo %Products%';
								|pl = 'Ten kod został już przypisany do towarów. %Products%';
								|tr = '%Products% öğesi için böyle kod zaten atandı'");
		ErrorDescription = StrReplace(ErrorDescription, "%Products%", """" + Selection.ProductsPresentation + """"
		                + ?(ValueIsFilled(Selection.Characteristic), " " + NStr("vi = 'với đặc tính';
																				|ru = 'с характеристикой';
																				|en = 'with variant'; fa = 'with variant';
																				|it = 'con la caratteristica';
																				|pl = 'z charakterystyką';
																				|tr = 'özellik ile'") + " """ + Selection.CharacteristicPresentation + """", "")
		                + ?(ValueIsFilled(Selection.Package), " " + NStr("vi = 'trong gói';
																		|ru = 'в упаковке';
																		|en = 'in packaging unit'; fa = 'in packaging unit';
																		|it = 'nella confezione';
																		|pl = 'w opakowaniu';
																		|tr = 'paketleme ünitesinde'") + " """ + Selection.PackagePresentation + """", ""));
		
		Message = New UserMessage;
		Message.Text = ErrorDescription;
		Message.Field = "Record.Code";
		Message.Message();
		Cancel = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CodeStartSelectionFromListOnServer()
	
	FreeCodes = OfflinePeripheralsServerCall.GetFreeCodes(Record.ExchangeRule, 20);
	NewRow = FreeCodes.Add();
	NewRow.Code = OfflinePeripheralsServerCall.GetMaximumCode(Record.ExchangeRule)+1;
	
	Items.Code.ChoiceList.Clear();
	For Each FreeCode In FreeCodes Do
		Items.Code.ChoiceList.Add(FreeCode.Code);
	EndDo;
	
EndProcedure

#EndRegion
