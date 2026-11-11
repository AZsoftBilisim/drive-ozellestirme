#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Checks the uniqueness of a directory element by a combination of the fields 'Code' and 'Traceable goods', if a record
// of traceable imported goods is kept.
//
// Parameters:
//	Cancel - Boolean - indication of failure of the directory element in the information database.
//
Procedure CheckForUniqueness(Cancel) Export
	
	If Cancel
		Or DeletionMark Then
		
		Return;
		
	EndIf;
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Date(1, 1, 1));
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	FEACN.Ref AS Ref
	|FROM
	|	Catalog.FEACN AS FEACN
	|WHERE
	|	FEACN.Code = &Code
	|	AND FEACN.Ref <> &Ref
	|	AND NOT FEACN.DeletionMark
	|	AND (NOT &UseTraceableImportedGoodsAccounting
	|		OR FEACN.TracedGoods = &TracedGoods)";
	
	Query.SetParameter("Code", Code);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("TracedGoods", TracedGoods);
	Query.SetParameter("UseTraceableImportedGoodsAccounting",
								UseTraceableImportedGoodsAccounting);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Cancel = True;
	
	If UseTraceableImportedGoodsAccounting Then
		ExceptionText = NStr("vi = 'Giá trị các trường ""Mã"" và ""Hàng hóa có nguồn gốc xuất xứ"" không đơn trị';
							|ru = 'Значения полей ""Код"" и ""Прослеживаемый товар"" не уникальны';
							|en = 'The ""Code"" and ""Traceable goods"" field values are not unique'; fa = 'The ""Code"" and ""Traceable goods"" field values are not unique';
							|it = 'I valori dei campi ""Codice"" e ""Articolo tracciabile"" non sono univoci';
							|pl = 'Wartości pól ""Kod"" i ""Kod identyfikowalny"" nie są unikalny';
							|tr = '""Kod"" ve ""İzlenebilir ürün"" alanlarının değerleri benzersiz değil'");
	Else
		ExceptionText = NStr("vi = 'Giá trị ""%1"" của trường ""Mã"" không đơn trị';
							|ru = 'Значение ""%1"" поля ""Код"" не уникально';
							|en = 'The ""%1"" value of the ""Code"" field is not unique'; fa = 'The ""%1"" value of the ""Code"" field is not unique';
							|it = 'Il valore ""%1"" del campo ""Codice"" non è univoco';
							|pl = 'Wartość ""%1"" pola ""Kod"" nie jest unikalna';
							|tr = '""Kod"" alan değeri ""%1"" benzersiz değil'");
		ExceptionText = StrTemplate(ExceptionText, Code);
	EndIf;
	
	Raise ExceptionText;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	AttributeDescription = Common.ObjectAttributeValue(Ref, "Description");
	If AttributeDescription = "rawmaterial owngoods"
		Or AttributeDescription = "nonprimary owngoods" Then
		
		MessageText = NStr("vi = 'Các mục dịch vụ có dấu hiệu thuộc tính hàng hóa đã được tạo khi cập nhật cơ sở thông tin. Chỉnh sửa của họ bị cấm.';
							|ru = 'Служебные элементы с указанием признака сырьевого товара созданы при обновлении информационной базы. Их редактирование запрещено.';
							|en = 'Service items with the Commodity attribute are created when updating the infobase. You cannot edit them.'; fa = 'Service items with the Commodity attribute are created when updating the infobase. You cannot edit them.';
							|it = 'Elementi di servizio con indicazione dell''attributo della merce grezza creati durante l''aggiornamento del database informatico. La loro modifica è vietata.';
							|pl = 'Elementy pomocnicze ze wskazaniem cechy towaru surowcowego przy aktualizacji bazy informacyjnej. Ich edycja jest zabroniona.';
							|tr = 'Infobase güncellenirken emtia bayrağı ile belirtilen özel öğeler oluşturuldu. Düzenlemeleri yasaktır.'");
		
		Common.MessageToUser(MessageText, ThisObject, "Description", , Cancel);
		
	EndIf;
	
	CheckForUniqueness(Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array();
	
	If ItemIsProcessed Then
		NotCheckedAttributeArray.Add("UnitOfMeasure");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf