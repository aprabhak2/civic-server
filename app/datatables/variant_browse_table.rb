class VariantBrowseTable < DatatableBase
  private
  FILTER_COLUMN_MAP = {
    'entrez_gene'         => 'genes.name',
    'variant'             => 'variants.name',
    'diseases'            => 'diseases.name',
  }.freeze

  ORDER_COLUMN_MAP = {
    'entrez_gene'         => 'entrez_name',
    'variant'             => 'variants.name',
    'diseases'            => 'disease_names',
    'evidence_item_count' => 'evidence_item_count'
  }.freeze

  def initial_scope
    Variant.datatable_scope
  end

  def presenter_class
    VariantBrowseRowPresenter
  end

  def select_query
    initial_scope.select('variants.id, variants.name, array_agg(distinct(diseases.name) order by diseases.name desc) as disease_names, max(genes.entrez_id) as entrez_id, max(genes.name) as entrez_name, count(distinct(evidence_items.id)) as evidence_item_count')
    .group('variants.id, variants.name')
  end

  def count_query
    initial_scope.select('COUNT(DISTINCT(variants.id)) as count')
  end
end
