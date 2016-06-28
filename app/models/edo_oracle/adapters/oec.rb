module EdoOracle
  module Adapters
    class Oec < EdoOracle::Oec
      extend EdoOracle::Adapters::Common

      def self.get_courses(term_code, filter)
        rows = super(term_id(term_code), filter)
        adapt_courses(rows, term_code)
      end

      def self.get_enrollments(term_code, select_clause, filter)
        rows = super(term_id(term_code), select_clause, filter)
        adapt_enrollments(rows, term_code)
      end

      def self.adapt_courses(rows, term_code)
        default_dates = default_edo_dates term_code
        user_courses = EdoOracle::UserCourses::Base.new
        rows.each do |row|
          uniq_ccn_lists row

          adapt_dept_name_and_catalog_id(row, user_courses)
          adapt_course_name row

          adapt_course_cntl_num row
          adapt_course_id(row, term_code)
          adapt_cross_listed_flag row
          adapt_dates(row, default_dates)
          adapt_evaluation_type row
          adapt_instructor_func row
          adapt_primary_secondary_cd row

          row['blue_role'] = '23'
        end
      end

      def self.adapt_enrollments(rows, term_code)
        rows.each do |row|
          adapt_course_id(row, term_code)
        end
      end

      # TODO This temporary logic, appropriate for Fall 2016 only, bridges a gap between legacy term data and EDO
      # section data on what counts as default course dates.
      def self.default_edo_dates(term_code)
        slug = Berkeley::TermCodes.to_slug *term_code.split('-')
        term = Berkeley::Terms.fetch.campus[slug]
        {
          start: term.classes_start.to_date.advance(days: 7).next_week(:wednesday),  # 2016-08-24 for Fall 2016
          end: term.classes_end.to_date.advance(days: -21).next_week(:friday)        # 2016-12-09 for Fall 2016
        }
      end

      def self.adapt_course_id(row, term_code)
        if row['section_id']
          row['course_id'] = "#{term_code}-#{row.delete 'section_id'}"
        end
      end

      def self.adapt_course_name(row)
        if row['dept_name']
          row['course_name'] = row.values_at('dept_name', 'catalog_id', 'instruction_format', 'section_num', 'course_title_short').join ' '
        end
      end

      def self.adapt_cross_listed_flag(row)
        row['cross_listed_flag'] = 'Y' if row['cross_listed_ccns'].present?
      end

      def self.adapt_dates(row, default_dates)
        if (row['start_date'] && row['end_date'])
          if (row['start_date'].to_date == default_dates[:start] && row['end_date'].to_date == default_dates[:end])
            row.delete 'start_date'
            row.delete 'end_date'
          else
            row['modular_course'] = 'Y'
            row['start_date'] = row['start_date'].strftime ::Oec::Worksheet::WORKSHEET_DATE_FORMAT
            row['end_date'] = row['end_date'].strftime ::Oec::Worksheet::WORKSHEET_DATE_FORMAT
          end
        end
      end

      def self.adapt_evaluation_type(row)
        row['evaluation_type'] = case row['affiliations']
                                   when /STUDENT/ then 'G'
                                   when /INSTRUCTOR/ then 'F'
                                 end
      end

      def self.uniq_ccn_lists(row)
        %w(co_scheduled_ccns cross_listed_ccns).each do |key|
          next unless row[key].present?
          ccns = row[key].split(',').uniq
          if ccns.count > 1
            row[key] = ccns.join(',')
          else
            row.delete key
          end
        end
      end

    end
  end
end