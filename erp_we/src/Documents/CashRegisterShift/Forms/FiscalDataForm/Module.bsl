
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	If Parameters.Property("CashRegisterShift") Then
		
		CashRegisterShift = Parameters.CashRegisterShift;
		
		Query = New Query();
		Query.Text = 
		"SELECT
		|	CashRegisterShift.FDOnShiftEndClosing AS FDOnShiftEndClosing
		|FROM
		|	Document.CashRegisterShift AS CashRegisterShift
		|WHERE
		|	CashRegisterShift.Ref = &CashRegisterShift";
		Query.SetParameter("CashRegisterShift", CashRegisterShift);
		
		Result = Query.Execute().Select();
		
		Result.Next();
		
		FDOnShiftEndClosing = Result.FDOnShiftEndClosing; // ValueStorage
		XMLString = FDOnShiftEndClosing.Get(); 
		If XMLString = Undefined Or Not TypeOf(XMLString) = Type("String") Or XMLString = "" Then
			Cancel = True;
			WarningText = NStr("vi = 'Không có dữ liệu tài chính';
								|ru = 'Нет фискальных данных';
								|en = 'No fiscal data'; fa = 'No fiscal data';
								|it = 'Nessun dato fiscale';
								|pl = 'Brak danych fiskalnych';
								|tr = 'Mali veri bulunmamaktadır'");
		Else
			FillTreeOfValuesByXMLString(AllDataTree, XMLString);
		EndIf;
		
	Else
		WarningText = NStr("vi = 'Biểu mẫu dữ liệu tài chính được dự định mở từ phần tử thay đổi thanh toán tiền mặt';
							|ru = 'Форма фискальных данных предназначена для открытия из элемента Кассовой смены';
							|en = 'Fiscal data form is opened from the POS shift item'; fa = 'Fiscal data form is opened from the POS shift item';
							|it = 'Il modulo dei dati fiscale è predisposto all''apertura dall''elemento Turno di cassa';
							|pl = 'Formularz danych fiskalnych jest przeznaczony do otwarcia z elementu Zmiany kasowej';
							|tr = 'Mali veri formunun Kasa vardiyası elemanından açılması amaçlanmıştır'");
		Raise WarningText;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillTreeOfValuesByXMLString(AllDataTree, XMLString)
	
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLString);
	
	FillElementsFromXMLReading(XMLReader, AllDataTree);
	
EndProcedure

&AtServer
Procedure FillElementsFromXMLReading(XMLReader, CurTreeElement)
	
	While XMLReader.Read() Do
		
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			
			NewItem = CurTreeElement.GetItems().Add();
			NewItem.Attribute = XMLReader.Name;
			NewItem.Value = XMLReader.Value;
			
			FillInAttributesFromReadingXML(XMLReader, NewItem);
			
			FillElementsFromXMLReading(XMLReader, NewItem);
			
		ElsIf XMLReader.NodeType = XMLNodeType.Text Then
			
			CurTreeElement.Value = XMLReader.Value;
			
		ElsIf XMLReader.NodeType = XMLNodeType.EndElement Then
			
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInAttributesFromReadingXML(XMLReader, CurTreeElement)
	
	If Not XMLReader.AttributeCount() = 0 Then
		
		For AttributeNumber = 0 To XMLReader.AttributeCount() - 1 Do
			NewItem = CurTreeElement.GetItems().Add();
			NewItem.Attribute = XMLReader.AttributeName(AttributeNumber);
			NewItem.Value = XMLReader.AttributeValue(AttributeNumber);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion
