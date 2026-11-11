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
	
	InformationSecurityUserSUID = InfoBaseUsers.CurrentUser().UUID;
	User = Catalogs.Users.FindByAttribute("IBUserID",
		New UUID(InformationSecurityUserSUID));
	
	CatalogNameReportOptions = "";
	Parameters.Property("CatalogNameReportOptions", CatalogNameReportOptions);
		
	ReportVariant = Undefined;
	If Parameters.Property("ReportVariant", ReportVariant) Then
		For Each SubordinateItem In Items.ButtonGroupViewReportsNested.ChildItems Do
			If SubordinateItem.Name <> "GroupButtonsDeleteReportSnapshot" Then
				SubordinateItem.Enabled = False;
			EndIf;
		EndDo;
	EndIf;
		
	UpdateReportsSnapshots(CatalogNameReportOptions, ReportVariant);

	If ReportsSnapshots.Count() > 0 Then
		CurrentReportSnapshot = 1;
		ReadReportSnapshot();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ReportsSnapshots(Command)
	
	OpenForm("InformationRegister.ReportsSnapshots.ListForm",
				New Structure("User", User));
	
EndProcedure

&AtClient
Procedure GoToEnd(Command)
	
	CurrentReportSnapshot = ReportsSnapshots.Count();
	ReadReportSnapshot();
	
EndProcedure

&AtClient
Procedure GoToBegin(Command)

	If ReportsSnapshots.Count() > 0 Then
		CurrentReportSnapshot = 1;
		ReadReportSnapshot();
	EndIf;

EndProcedure

&AtClient
Procedure GoBack(Command)
	
	If CurrentReportSnapshot > 1 Then
		CurrentReportSnapshot = CurrentReportSnapshot - 1;
		ReadReportSnapshot();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoForward(Command)
	
	If CurrentReportSnapshot < ReportsSnapshots.Count() Then
		CurrentReportSnapshot = CurrentReportSnapshot + 1;
		ReadReportSnapshot();
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteReportSnapshot(Command)
	
	If CurrentReportSnapshot <> 0 Then
		DeleteReportSnapshotAtServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateReportsSnapshots(CatalogNameReportOptions, ReportVariant)
	
	UserReportsSnapshots = InformationRegisters.ReportsSnapshots.UserReportsSnapshots(User, CatalogNameReportOptions);
	UserReportsSnapshots.FillValues(User, "User");
	
	If ValueIsFilled(ReportVariant) Then
		Counter = 0;
		While Counter < UserReportsSnapshots.Count() Do
			If UserReportsSnapshots[Counter].Variant = ReportVariant Then
				Counter = Counter + 1;
			Else
				UserReportsSnapshots.Delete(Counter);
			EndIf;
		EndDo;
	EndIf;	
	
	ReportsSnapshots.Load(UserReportsSnapshots);
	
EndProcedure

&AtServer
Procedure ReadReportSnapshot()
	
	RowReport = ReportsSnapshots[CurrentReportSnapshot-1];
	
	ReportSpreadsheetDocument.Clear();
	UpdateDate = Undefined;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ReportsSnapshots");
	LockItem.SetValue("User", RowReport.User);
	LockItem.SetValue("Report", RowReport.Report);
	LockItem.SetValue("Variant", RowReport.Variant);
	LockItem.SetValue("UserSettingsHash", RowReport.UserSettingsHash);

	BeginTransaction();
	Try
		Block.Lock();

		RecordManager = InformationRegisters.ReportsSnapshots.CreateRecordManager();
		FillPropertyValues(RecordManager, RowReport);
		RecordManager.Read();
		If RecordManager.Selected() Then
			If RecordManager.ReportUpdateError Then
				Common.MessageToUser(NStr("vi = 'Sai ảnh chụp báo cáo, cần ghi lại nó.';
											|ru = 'Некорректный снимок отчета, необходимо его перезаписать.';
											|en = 'Invalid report snapshot. Overwrite the snapshot.'; fa = 'Invalid report snapshot. Overwrite the snapshot.';
											|it = 'Invalid report snapshot. Overwrite the snapshot.';
											|pl = 'Invalid report snapshot. Overwrite the snapshot.';
											|tr = 'Raporun alıntısı yanlış, üzerine yazılması gerekmektedir.'"));
			Else
				ReportResult = RecordManager.ReportResult.Get();
				If TypeOf(ReportResult) = Type("SpreadsheetDocument") Then
					ReportSpreadsheetDocument.Put(ReportResult);
					RecordManager.LastViewedDate = CurrentSessionDate();
					RecordManager.Write();
				Else
					Common.MessageToUser(NStr("vi = 'Sai ảnh chụp báo cáo.';
												|ru = 'Некорректный снимок отчета.';
												|en = 'Invalid report snapshot.'; fa = 'Invalid report snapshot.';
												|it = 'Invalid report snapshot.';
												|pl = 'Invalid report snapshot.';
												|tr = 'Rapor alıntısı yanlış.'"));
				EndIf;
			EndIf;
			UpdateDate = RecordManager.UpdateDate;
		Else
			Common.MessageToUser(NStr("vi = 'Ảnh chụp báo cáo không tồn tại (báo cáo bị xóa).';
										|ru = 'Несуществующий снимок отчета (отчет был удален).';
										|en = 'The report snippet does not exist. The report was deleted.'; fa = 'The report snippet does not exist. The report was deleted.';
										|it = 'The report snippet does not exist. The report was deleted.';
										|pl = 'The report snippet does not exist. The report was deleted.';
										|tr = 'Rapor alıntısı mevcut değil (rapor silindi).'"));
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Title = NStr("vi = 'Tính cập nhật';
				|ru = 'Актуальность';
				|en = 'Last updated'; fa = 'آخرین به‌روزرسانی';
				|it = 'Актуальность';
				|pl = 'Last updated';
				|tr = 'Uygunluk'") + ": " + UpdateDate;
	
EndProcedure

&AtServer
Procedure DeleteReportSnapshotAtServer()
	
	RowReport = ReportsSnapshots[CurrentReportSnapshot-1];
	
	ReportSpreadsheetDocument.Clear();
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ReportsSnapshots");
	LockItem.SetValue("User", RowReport.User);
	LockItem.SetValue("Report", RowReport.Report);
	LockItem.SetValue("Variant", RowReport.Variant);
	LockItem.SetValue("UserSettingsHash", RowReport.UserSettingsHash);

	BeginTransaction();
	Try
		Block.Lock();
		RecordManager = InformationRegisters.ReportsSnapshots.CreateRecordManager();
		FillPropertyValues(RecordManager, RowReport);
		RecordManager.Read();
		If RecordManager.Selected() Then
			RecordManager.Delete();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	ReportsSnapshots.Delete(RowReport);
	
	If CurrentReportSnapshot > ReportsSnapshots.Count() Then
		CurrentReportSnapshot = ReportsSnapshots.Count();
	EndIf;
	
	If CurrentReportSnapshot > 0 Then
		ReadReportSnapshot();
	EndIf;
	
EndProcedure

#EndRegion