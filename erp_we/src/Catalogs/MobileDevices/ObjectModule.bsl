#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	If Not IsFolder Then
		SerialNumber="";
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	CheckRecordingCapability(Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckRecordingCapability(Cancel)
	
	QueryText =
	"SELECT ALLOWED
	|	MobileDevices.Ref
	|FROM
	|	Catalog.MobileDevices AS MobileDevices
	|WHERE
	|	MobileDevices.SerialNumber = &SerialNumber
	|	AND MobileDevices.Ref <> &Ref"
	;
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("SerialNumber", SerialNumber);
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		MessageText = NStr("vi = 'Đang tồn tại trong danh mục máy tính xách tay có số sê-ri được chỉ định';
							|ru = 'Мобильный компьютер с указанным серийным номером уже имеется в справочнике';
							|en = 'Mobile computer with the specified serial number already exists in the catalog'; fa = 'Mobile computer with the specified serial number already exists in the catalog';
							|it = 'Un computer mobile con un numero seriale indicato è già presente in elenco';
							|pl = 'Komputer mobilny z podanym numerem seryjnym jest już w katalogu';
							|tr = 'Katalogda zaten belirtilen seri numarasına sahip bir mobil bilgisayar mevcut'");
		CommonClientServer.MessageToUser(MessageText, ThisObject, "SerialNumber",, Cancel);
	EndIf;
	
EndProcedure
	
#EndRegion

#EndIf