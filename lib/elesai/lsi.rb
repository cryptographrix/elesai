module Elesai

  class LSIArray

    attr_reader :adapters, :virtualdrives, :physicaldrives, :enclosures

    def initialize(opts)
      @adapters = []
      @virtualdrives = []
      @physicaldrives = {}
      @enclosures = []
      @spans = []

      case opts[:hint]
        when :pd,:physicaldrive
          PDlist_aAll.new.parse!(self,opts)
        when :vd,:virtualdrive
          LDPDinfo_aAll.new.parse!(self,opts)
        else
          PDlist_aAll.new.parse!(self,opts)
          LDPDinfo_aAll.new.parse!(self,opts)
      end
    end

    def add_adapter(a)
      @adapters[a[:id]] = a if @adapters[a[:id]].nil?
    end

    def add_virtualdrive(vd)
      @virtualdrives.push(vd)
    end

    def add_physicaldrive(pd)
      @physicaldrives[pd._id] = pd if @physicaldrives[pd._id].nil?
      @physicaldrives[pd._id]
    end

    def to_s
      lsiarrayout = "LSI Array\n"
      @adapters.each do |adapter|
        lsiarrayout += "  adapter #{adapter.id}\n"
        adapter.virtualdrives.each do |virtualdrive|
          lsiarrayout += "    +--+ #{virtualdrive.to_str}\n"
          virtualdrive.physicaldrives.each do |id,physicaldrive|
            lsiarrayout += "    |  |-- pd #{physicaldrive.to_str}\n"
          end
        end
      end
      lsiarrayout
    end

    ### Adapter

    class Adapter < Hash

      def initialize
        self[:virtualdrives] = []
        self[:physicaldrives] = {}
        super
      end

      def _id
        "#{self[:id]}"
      end

      def type
        :adapter
      end

      def type_of?(type)
        self.type == type
      end

      def inspect
        "#{self.class}:#{self.__id__}"
      end

      def add_physicaldrive(pd)
        self[:physicaldrives][pd._id] = pd unless self[:physicaldrives][pd._id].nil?
      end

    end

    ### Virtual Drive

    class VirtualDrive < Hash

      STATES = {
          :optimal              => 'Optimal',
          :degraded             => 'Degraded',
          :partial_degraded     => 'Partial Degraded',
          :failed               => 'Failed',
          :offline              => 'Offline'
      }

      class Size < Struct.new(:number, :unit)
        def to_s ; "%8.2f%s" % [self.number,self.unit] end
      end
      class RaidLevel < Struct.new(:primary, :secondary)
        def to_s ; "raid%s:raid%s" % [self.primary,self.secondary] end
      end

      def initialize
        self[:physicaldrives] = []
      end

      def _id
        self[:targetid]
      end

      def type
        :virtualdrive
      end

      def type_of?(type)
        self.type == type
      end

      def inspect
        "#{self.class}:#{self.__id__}"
      end

      def add_physicaldrive(pd)

      end

      def to_s
        "[VD] %4s %18s %s %s %d" % [ self._id, self[:state], self[:size], self[:raidlevel], self[:physicaldrives].size ]
      end

    end

    ### Physical Drive

    class PhysicalDrive < Hash

      STATES = {
          :online               => 'Online',
          :unconfigured_good    => 'Unconfigured(good)',
          :hotspare             => 'Hotspare',
          :failed               => 'Failed',
          :rebuild              => 'Rebuild',
          :unconfigured_bad     => 'Unconfigured(bad)',
          :missing              => 'Missing',
          :offline              => 'Offline'
      }

      SPINS = {
          :spun_up              => 'Spun up'
      }

      class Size < Struct.new(:number, :unit)
        def to_s ; "%8.2f%s" % [self.number,self.unit] end
      end
      class FirmwareState < Struct.new(:state, :spin)
        def to_s
          "#{self.state}:#{self.spin}"
        end
      end

      def initialize
        self[:_adapter] = nil
        self[:_virtualdrives] = []
      end

      def _id
        "e#{self[:enclosuredeviceid].to_s}s#{self[:slotnumber].to_s}".to_sym
      end

      def type
        :physicaldrive
      end

      def type_of?(type)
        self.type == type
      end

      def to_s
        keys = [:deviceid, :firmwarestate, :coercedsize, :mediatype, :pdtype, :mediaerrorcount, :predictivefailurecount,:inquirydata]
        #"[PD] %8s %4s %19s %8.2f%s %5s %5s %3d %3d   %s" % [ self.id, @deviceid, "#{@state}:#{@spin}", @_size.number, @_size.unit, @mediatype, @pdtype, @mediaerrors, @predictivefailure, @inquirydata  ]
        "[PD] %8s %4s %19s %s %5s %5s %3d %3d  a%s  %s" % [ self._id, self[:deviceid], self[:firmwarestate], self[:coercedsize], self[:mediatype], self[:pdtype], self[:mediaerrorcount], self[:predictivefailurecount], self[:_adapter]._id, self[:inquirydata] ]
      end

      def inspect
        "#{self.class}:#{self.__id__}"
      end

      def add_adapter(a)
        self[:_adapter] = a
      end

      def get_adapter
        self[:_adapter]
      end

      def add_virtualdrive(vd)
         self[:_virtualdrives][vd._id] = vd if self[:_virtualdrives][vd._id].nil?
      end

      def get_virtualdrive(vd_id)
        self[:_virtualdrives][vd_id]
      end

      def get_virtualdrives
        self[:_virtualdrives]
      end
    end
  end
end
