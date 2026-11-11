///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers
 
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.RecordStructure = Undefined Then
		Common.MessageToUser(NStr(
			"vi = 'Chỉ có thể xem ảnh chụp báo cáo từ danh sách ảnh chụp báo cáo của người sử dụng.';
			|ru = 'Просмотр снимка отчета доступен только из списка снимков отчетов пользователя.';
			|en = 'You can view a report snapshot only from the list of user report snapshots.'; fa = 'You can view a report snapshot only from the list of user report snapshots.';
			|it = 'Просмотр снимка отчета доступен только из списка снимков отчетов пользователя.';
			|pl = 'You can view a report snapshot only from the list of user report snapshots.';
			|tr = 'Raporun anlık görüntüsünü görüntülemek sadece kullanıcı raporlarının anlık görüntüleri listesinden yapılabilir.'"), , , , Cancel);
		Return;
	EndIf;
	
	RecordStructure = Parameters.RecordStructure;

	FillPropertyValues(ThisObject, RecordStructure);

	SetPrivilegedMode(True);

	Record = InformationRegisters.ReportsSnapshots.CreateRecordManager();
	FillPropertyValues(Record, Parameters.RecordStructure);
	Record.Read();
	If Not Record.Selected() Then
		Common.MessageToUser(NStr("vi = 'Không tìm thấy bản ghi theo tham số chỉ định.';
									|ru = 'Не найдена запись по указанным параметрам.';
									|en = 'No record is found by the specified parameters.'; fa = 'No record is found by the specified parameters.';
									|it = 'Не найдена запись по указанным параметрам.';
									|pl = 'No record is found by the specified parameters.';
									|tr = 'Belirtilen parametrelerle eşleşen kayıt bulunamadı.'"), , , , Cancel);
	ElsIf Record.ReportUpdateError Then
		Common.MessageToUser(NStr("vi = 'Chưa tạo ảnh chụp báo cáo.';
									|ru = 'Снимок отчета не был сформирован.';
									|en = 'Report snapshot is not generated.'; fa = 'Report snapshot is not generated.';
									|it = 'Снимок отчета не был сформирован.';
									|pl = 'Report snapshot is not generated.';
									|tr = 'Raporun anlık görüntüsü oluşturulmadı.'"), , , , Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf;

	ReportResult = Record.ReportResult.Get();
	If TypeOf(ReportResult) = Type("SpreadsheetDocument") Then
		TabDocument.Put(ReportResult);
	Else
		Common.MessageToUser(NStr("vi = 'Sai ảnh chụp báo cáo.';
									|ru = 'Некорректный снимок отчета.';
									|en = 'Invalid report snapshot.'; fa = 'Invalid report snapshot.';
									|it = 'Invalid report snapshot.';
									|pl = 'Invalid report snapshot.';
									|tr = 'Rapor alıntısı yanlış.'"), , , , Cancel);
	EndIf;

	If Not Cancel Then
		Record.LastViewedDate = CurrentSessionDate();
		Record.Write();
	EndIf;

	SetPrivilegedMode(False);

EndProcedure

#EndRegion