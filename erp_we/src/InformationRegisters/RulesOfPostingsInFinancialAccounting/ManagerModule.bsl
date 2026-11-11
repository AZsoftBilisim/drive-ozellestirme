
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Includes the use of a posting template (matching accounts / turnover) in the configuration of the formation of postings.
// 
// Parameters:
// 	PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting - Setting to include the transaction template in 
// 	PostingTemplate - CatalogRef.PostingTemplatesForFinancialAccounting,
// 					 Reference link.According to the accounts of the international accounting
// 					 Reference link.International Accounting Turnover Compliance - Posting template (matching accounts / turnover).
//
Procedure IncludeInPostingGenerationSetting(PostingGenerationSetting, PostingTemplate) Export
	
	RecordSet = InformationRegisters.RulesOfPostingsInFinancialAccounting.CreateRecordSet();
	RecordSet.Filter.PostingGenerationSetting.Set(PostingGenerationSetting);
	RecordSet.Filter.PostingTemplate.Set(PostingTemplate);
	
	NewRecord = RecordSet.Add();
	NewRecord.PostingGenerationSetting = PostingGenerationSetting;
	NewRecord.PostingTemplate = PostingTemplate;
	
	RecordSet.Write();
	
EndProcedure

#EndRegion

#EndIf
